import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/supabase/edge_api.dart';
import 'package:udyogasethu/features/trust/domain/kyc_record.dart';

abstract class KycRepository {
  Future<List<KycRecord>> getKycRecords(String userId);
  Future<KycRecord?> getLatestKycRecord(String userId, {String docType = 'aadhaar'});
  Stream<KycRecord?> watchKycRecord(String userId, {String docType = 'aadhaar'});
  Future<Map<String, dynamic>> startKycSession({required String docType, String? redirectUrl});
  Future<Map<String, dynamic>> simulateCallback({required String providerRef, required String docType});
}

class SupabaseKycRepository implements KycRepository {
  final SupabaseClient? _client;
  final EdgeApiClient edgeApi;
  static final Map<String, KycRecord> _mockStorage = {};

  static SupabaseClient? _safeClient(SupabaseClient? client) {
    if (client != null && !client.rest.url.contains('dummy.supabase.co')) {
      return client;
    }
    try {
      if (Supabase.instance.isInitialized &&
          !Supabase.instance.client.rest.url.contains('dummy.supabase.co')) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }

  SupabaseKycRepository({SupabaseClient? client, required this.edgeApi})
      : _client = _safeClient(client);

  @override
  Future<List<KycRecord>> getKycRecords(String userId) async {
    try {
      if (_client == null) {
        return _mockStorage.values.where((r) => r.userId == userId).toList();
      }

      final List<dynamic> data = await _client
          .from('kyc_records')
          .select('*')
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      final records = data.map((json) => KycRecord.fromJson(json as Map<String, dynamic>)).toList();
      for (final r in records) {
        _mockStorage['${r.userId}_${r.docType}'] = r;
      }
      return records;
    } catch (e, stack) {
      AppLogger.e('Error fetching KYC records', e, stack);
      return _mockStorage.values.where((r) => r.userId == userId).toList();
    }
  }

  @override
  Future<KycRecord?> getLatestKycRecord(String userId, {String docType = 'aadhaar'}) async {
    try {
      if (_client == null) {
        return _mockStorage['${userId}_$docType'];
      }

      final data = await _client
          .from('kyc_records')
          .select('*')
          .eq('user_id', userId)
          .eq('doc_type', docType)
          .maybeSingle();

      if (data != null) {
        final record = KycRecord.fromJson(data);
        _mockStorage['${userId}_$docType'] = record;
        return record;
      }
      return _mockStorage['${userId}_$docType'];
    } catch (e, stack) {
      AppLogger.e('Error fetching latest KYC record for $docType', e, stack);
      return _mockStorage['${userId}_$docType'];
    }
  }

  @override
  Stream<KycRecord?> watchKycRecord(String userId, {String docType = 'aadhaar'}) {
    final controller = StreamController<KycRecord?>.broadcast();

    // Send initial cached value synchronously
    final initial = _mockStorage['${userId}_$docType'];
    controller.add(initial);

    if (_client != null) {
      getLatestKycRecord(userId, docType: docType).then((record) {
        if (!controller.isClosed) controller.add(record);
      });
      // Supabase Realtime channel stream listener
      final channel = _client.channel('public:kyc_records:user=$userId');
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'kyc_records',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          final newRecordJson = payload.newRecord;
          if (newRecordJson.isNotEmpty) {
            final record = KycRecord.fromJson(newRecordJson);
            if (record.docType == docType) {
              _mockStorage['${userId}_$docType'] = record;
              if (!controller.isClosed) controller.add(record);
            }
          }
        },
      ).subscribe();

      controller.onCancel = () {
        _client.removeChannel(channel);
      };
    }

    return controller.stream;
  }

  @override
  Future<Map<String, dynamic>> startKycSession({required String docType, String? redirectUrl}) async {
    final user = _client?.auth.currentUser;
    final userId = user?.id ?? 'demo_user_123';
    final providerRef = 'mock_kyc_${userId.slice(0, 8)}_${DateTime.now().millisecondsSinceEpoch}';

    // Store initial pending state in mock storage
    _mockStorage['${userId}_$docType'] = KycRecord(
      id: 'kyc_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      docType: docType,
      provider: 'digilocker_mock',
      providerRef: providerRef,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    try {
      return await edgeApi.kycStart(docType: docType, redirectUrl: redirectUrl);
    } catch (_) {
      // Return simulated success response if edge function offline in mock
      return {
        'success': true,
        'provider': 'digilocker_mock',
        'provider_ref': providerRef,
        'redirect_url': 'udyogasethu://kyc/callback?provider_ref=$providerRef&doc_type=$docType&status=verified',
        'is_demo_mode': true,
      };
    }
  }

  @override
  Future<Map<String, dynamic>> simulateCallback({required String providerRef, required String docType}) async {
    final user = _client?.auth.currentUser;
    final userId = user?.id ?? 'demo_user_123';

    try {
      final res = await edgeApi.kycCallback(
        providerRef: providerRef,
        status: 'verified',
        maskedId: 'XXXX-XXXX-4321',
      );

      _mockStorage['${userId}_$docType'] = KycRecord(
        id: 'kyc_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        docType: docType,
        provider: 'digilocker_mock',
        providerRef: providerRef,
        status: 'verified',
        maskedId: 'XXXX-XXXX-4321',
        nameMasked: 'R***** S****',
        verifiedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      return res;
    } catch (_) {
      final mockRecord = KycRecord(
        id: 'kyc_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        docType: docType,
        provider: 'digilocker_mock',
        providerRef: providerRef,
        status: 'verified',
        maskedId: 'XXXX-XXXX-4321',
        nameMasked: 'R***** S****',
        verifiedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      _mockStorage['${userId}_$docType'] = mockRecord;

      return {
        'success': true,
        'status': 'verified',
        'masked_id': 'XXXX-XXXX-4321',
        'name_masked': 'R***** S****',
        'verified_at': DateTime.now().toIso8601String(),
      };
    }
  }
}

extension StringSlice on String {
  String slice(int start, [int? end]) {
    final e = end ?? length;
    if (start >= length) return '';
    return substring(start, e > length ? length : e);
  }
}

final kycRepositoryProvider = Provider<KycRepository>((ref) {
  final edgeApi = ref.watch(edgeApiClientProvider);
  return SupabaseKycRepository(edgeApi: edgeApi);
});
