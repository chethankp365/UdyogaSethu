import { handleCors } from '../_shared/cors.ts';
import { logInfo, logError } from '../_shared/logger.ts';
import { jsonResponse, errorResponse } from '../_shared/response.ts';
import { getServiceClient } from '../_shared/supabase.ts';

// Candidate resource ID for "Current Daily Price of Various Commodities from Various Markets (Mandi)" on data.gov.in
const AGMARKNET_RESOURCE_ID = '9ef84268-d588-465a-a308-a864a43d0070';

interface AgmarknetRecord {
  state?: string;
  district?: string;
  market?: string;
  commodity?: string;
  variety?: string;
  arrival_date?: string;
  min_price?: string | number;
  max_price?: string | number;
  modal_price?: string | number;
}

Deno.serve(async (req: Request) => {
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  const url = new URL(req.url);
  let action = url.searchParams.get('action');
  let bodyJson: Record<string, unknown> = {};

  if (req.method === 'POST') {
    try {
      bodyJson = await req.json();
      if (bodyJson.health === true || bodyJson.action === 'health') {
        action = 'health';
      }
    } catch (_) {
      // Not JSON or empty body
    }
  }

  if (!action) {
    action = req.method === 'GET' ? 'health' : 'sync';
  }

  const supabase = getServiceClient();

  // 1. HEALTH CHECK PATH
  // Returns number of rows stored in database and newest arrival_date without exposing any secrets
  if (action === 'health') {
    try {
      const { data: stats, error: statsErr } = await supabase
        .from('mandi_prices')
        .select('arrival_date')
        .order('arrival_date', { ascending: false })
        .limit(1);

      const { count, error: countErr } = await supabase
        .from('mandi_prices')
        .select('*', { count: 'exact', head: true });

      const newestDate = stats && stats.length > 0 ? stats[0].arrival_date : null;
      const isApiKeyConfigured = Boolean(Deno.env.get('DATA_GOV_API_KEY'));
      const isSyncEnabled = Deno.env.get('MANDI_SYNC_ENABLED') === 'true';

      return jsonResponse({
        ok: true,
        status: 'healthy',
        resource_id: AGMARKNET_RESOURCE_ID,
        is_sync_enabled: isSyncEnabled,
        is_api_key_configured: isApiKeyConfigured,
        total_rows_stored: count ?? 0,
        newest_arrival_date: newestDate,
        message: isSyncEnabled
          ? 'Live sync is enabled and operational.'
          : 'Live sync is currently switched off by configuration (MANDI_SYNC_ENABLED=false). Using stored APMC price feeds.',
      });
    } catch (err) {
      logError('mandi_health_check_failed', err);
      return errorResponse('health_check_failed', 'Failed to inspect mandi database', 500);
    }
  }

  // 2. MANUAL "SYNC NOW" PATH
  if (req.method === 'POST') {
    try {
      const isSyncEnabled = Deno.env.get('MANDI_SYNC_ENABLED') === 'true';

      // Check current latest data before doing anything
      const { data: latestExisting } = await supabase
        .from('mandi_prices')
        .select('arrival_date')
        .order('arrival_date', { ascending: false })
        .limit(1);
      const currentNewest = latestExisting && latestExisting.length > 0 ? latestExisting[0].arrival_date : null;

      // If switched off per user instructions, safely return status without crashing or calling external API
      if (!isSyncEnabled) {
        logInfo('mandi_sync_skipped_disabled', {
          reason: 'MANDI_SYNC_ENABLED is not set to true',
        });

        return jsonResponse({
          status: 'switched_off',
          message: 'Mandi live sync is currently switched off. Stored APMC data was preserved.',
          resource_id: AGMARKNET_RESOURCE_ID,
          rows_fetched: 0,
          rows_upserted: 0,
          newest_arrival_date: currentNewest,
        });
      }

      // If switched on, read secret
      const apiKey = Deno.env.get('DATA_GOV_API_KEY');
      if (!apiKey) {
        return errorResponse(
          'api_key_missing',
          'DATA_GOV_API_KEY secret is not configured in Edge Function secrets',
          400
        );
      }

      logInfo('mandi_sync_started', { resourceId: AGMARKNET_RESOURCE_ID });

      // Fetch from data.gov.in Agmarknet API for Karnataka
      const apiUrl = new URL(`https://api.data.gov.in/resource/${AGMARKNET_RESOURCE_ID}`);
      apiUrl.searchParams.set('api-key', apiKey);
      apiUrl.searchParams.set('format', 'json');
      apiUrl.searchParams.set('filters[state]', 'Karnataka');
      apiUrl.searchParams.set('limit', '250');

      let response: Response;
      try {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 12000); // 12s timeout
        response = await fetch(apiUrl.toString(), { signal: controller.signal });
        clearTimeout(timeout);
      } catch (networkErr) {
        logError('mandi_fetch_network_error', networkErr);
        // KEEP LAST GOOD DATA
        return jsonResponse({
          status: 'api_unreachable_kept_last_good_data',
          message: 'Agmarknet API was unreachable from network. Last stored mandi data was retained.',
          rows_fetched: 0,
          rows_upserted: 0,
          newest_arrival_date: currentNewest,
        });
      }

      if (!response.ok) {
        logError('mandi_api_bad_response', { status: response.status });
        // KEEP LAST GOOD DATA
        return jsonResponse({
          status: 'api_error_kept_last_good_data',
          message: `Agmarknet API returned status ${response.status}. Retained last good data.`,
          rows_fetched: 0,
          rows_upserted: 0,
          newest_arrival_date: currentNewest,
        });
      }

      const payload = await response.json();
      const records: AgmarknetRecord[] = payload.records || [];

      if (!records || records.length === 0) {
        return jsonResponse({
          status: 'no_new_records',
          message: 'No records returned by Agmarknet for today. Retained existing prices.',
          rows_fetched: 0,
          rows_upserted: 0,
          newest_arrival_date: currentNewest,
        });
      }

      // Transform and sanitize records
      const upsertRows = records.map((r) => {
        const minP = typeof r.min_price === 'number' ? r.min_price : parseFloat(r.min_price || '0') || 0;
        const maxP = typeof r.max_price === 'number' ? r.max_price : parseFloat(r.max_price || '0') || minP;
        const modalP = typeof r.modal_price === 'number' ? r.modal_price : parseFloat(r.modal_price || '0') || minP;

        // Parse date (typically DD/MM/YYYY or YYYY-MM-DD)
        let formattedDate = new Date().toISOString().split('T')[0];
        if (r.arrival_date) {
          const parts = r.arrival_date.split('/');
          if (parts.length === 3) {
            // DD/MM/YYYY -> YYYY-MM-DD
            formattedDate = `${parts[2]}-${parts[1].padStart(2, '0')}-${parts[0].padStart(2, '0')}`;
          } else if (r.arrival_date.includes('-')) {
            formattedDate = r.arrival_date;
          }
        }

        return {
          state: r.state || 'Karnataka',
          district: r.district || 'General',
          market: r.market || 'APMC Yard',
          commodity: r.commodity || 'Produce',
          variety: r.variety || 'Common',
          arrival_date: formattedDate,
          min_price: minP,
          max_price: maxP,
          modal_price: modalP,
          updated_at: new Date().toISOString(),
        };
      });

      // Upsert into Supabase
      const { data: upsertedData, error: upsertErr } = await supabase
        .from('mandi_prices')
        .upsert(upsertRows, {
          onConflict: 'commodity,market,variety,arrival_date',
        })
        .select('arrival_date');

      if (upsertErr) {
        logError('mandi_upsert_error', upsertErr);
        return errorResponse('database_error', 'Failed to upsert records into mandi_prices', 500);
      }

      const newestDate = upsertRows.reduce(
        (max, r) => (r.arrival_date > max ? r.arrival_date : max),
        currentNewest || ''
      );

      logInfo('mandi_sync_completed', {
        fetched: records.length,
        upserted: upsertRows.length,
        newestDate,
      });

      return jsonResponse({
        status: 'synced_successfully',
        resource_id: AGMARKNET_RESOURCE_ID,
        rows_fetched: records.length,
        rows_upserted: upsertRows.length,
        newest_arrival_date: newestDate,
      });
    } catch (err) {
      logError('mandi_sync_exception', err);
      return errorResponse('internal_error', 'Internal error occurred during mandi sync', 500);
    }
  }

  return errorResponse('method_not_allowed', 'Method not allowed. Use GET for health or POST for sync.', 405);
});
