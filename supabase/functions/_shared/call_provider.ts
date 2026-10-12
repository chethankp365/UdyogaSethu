// CallProvider interface and implementations for Protected Masked Voice Proxy (Step P7.2)

export interface InitiateCallParams {
  callerId: string;
  recipientId: string;
  callerPhone?: string;
  recipientPhone?: string;
  bookingCode?: string;
  assignmentId?: string;
}

export interface CallResult {
  provider: string;
  call_sid: string;
  status: 'connected' | 'initiated' | 'failed';
  proxy_display: string;
  is_demo: boolean;
  notes?: string;
}

export interface EndCallParams {
  callSid: string;
  durationSeconds?: number;
}

export interface EndCallResult {
  ok: boolean;
  status: 'completed' | 'failed';
  durationSeconds: number;
}

export interface CallProvider {
  readonly name: string;
  readonly isDemo: boolean;
  initiateCall(params: InitiateCallParams): Promise<CallResult>;
  endCall(params: EndCallParams): Promise<EndCallResult>;
}

/**
 * MockCallProvider: Default provider when CALL_PROVIDER=mock (or unset).
 * Simulates an active proxy bridge without connecting to live telecom trunks.
 * Real phone numbers are NEVER sent to the client or returned in JSON responses.
 */
export class MockCallProvider implements CallProvider {
  readonly name = 'mock';
  readonly isDemo = true;
  private readonly proxyNumber = '+91 80 4719 8200';

  async initiateCall(params: InitiateCallParams): Promise<CallResult> {
    const callSid = `mock_call_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
    return {
      provider: this.name,
      call_sid: callSid,
      status: 'connected',
      proxy_display: `${this.proxyNumber} (Udyoga Proxy)`,
      is_demo: true,
      notes: 'Demo mode: Proxy simulated without real telecom bridge',
    };
  }

  async endCall(params: EndCallParams): Promise<EndCallResult> {
    return {
      ok: true,
      status: 'completed',
      durationSeconds: params.durationSeconds || 0,
    };
  }
}

/**
 * TwilioCallProvider: Live telecom bridge via Twilio Voice API.
 * Uses Twilio REST API to connect caller to proxy, then dials recipient.
 */
export class TwilioCallProvider implements CallProvider {
  readonly name = 'twilio';
  readonly isDemo = false;

  private accountSid = Deno.env.get('TWILIO_ACCOUNT_SID') || '';
  private authToken = Deno.env.get('TWILIO_AUTH_TOKEN') || '';
  private fromNumber = Deno.env.get('TWILIO_FROM_NUMBER') || '+918047198200';

  async initiateCall(params: InitiateCallParams): Promise<CallResult> {
    if (!this.accountSid || !this.authToken || !params.callerPhone || !params.recipientPhone) {
      // Fallback to demo mode if credentials or numbers missing
      return {
        provider: this.name,
        call_sid: `twilio_fallback_${Date.now()}`,
        status: 'initiated',
        proxy_display: `${this.fromNumber} (Twilio Proxy)`,
        is_demo: true,
        notes: 'Twilio credentials not configured in secrets; running in fallback demo mode',
      };
    }

    try {
      // Basic Twilio click-to-call REST integration
      const url = `https://api.twilio.com/2010-04-01/Accounts/${this.accountSid}/Calls.json`;
      const auth = btoa(`${this.accountSid}:${this.authToken}`);
      const body = new URLSearchParams({
        To: params.callerPhone,
        From: this.fromNumber,
        Url: `https://handler.twilio.com/twiml/bridge?to=${encodeURIComponent(params.recipientPhone)}`,
      });

      const res = await fetch(url, {
        method: 'POST',
        headers: {
          Authorization: `Basic ${auth}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body.toString(),
      });

      if (!res.ok) {
        const errText = await res.text();
        return {
          provider: this.name,
          call_sid: `twilio_err_${Date.now()}`,
          status: 'failed',
          proxy_display: `${this.fromNumber} (Twilio Proxy)`,
          is_demo: false,
          notes: `Twilio call request failed: ${res.statusText} - ${errText}`,
        };
      }

      const data = await res.json();
      return {
        provider: this.name,
        call_sid: data.sid || `twilio_${Date.now()}`,
        status: 'connected',
        proxy_display: `${this.fromNumber} (Twilio Proxy)`,
        is_demo: false,
      };
    } catch (e: any) {
      return {
        provider: this.name,
        call_sid: `twilio_exc_${Date.now()}`,
        status: 'failed',
        proxy_display: `${this.fromNumber} (Twilio Proxy)`,
        is_demo: false,
        notes: `Twilio exception: ${e.message}`,
      };
    }
  }

  async endCall(params: EndCallParams): Promise<EndCallResult> {
    return {
      ok: true,
      status: 'completed',
      durationSeconds: params.durationSeconds || 0,
    };
  }
}

/**
 * ExotelCallProvider: Indian telecom bridge via Exotel API.
 */
export class ExotelCallProvider implements CallProvider {
  readonly name = 'exotel';
  readonly isDemo = false;

  private sid = Deno.env.get('EXOTEL_SID') || '';
  private token = Deno.env.get('EXOTEL_TOKEN') || '';
  private callerId = Deno.env.get('EXOTEL_CALLER_ID') || '08047198200';
  private subdomain = Deno.env.get('EXOTEL_SUBDOMAIN') || 'api.exotel.com';

  async initiateCall(params: InitiateCallParams): Promise<CallResult> {
    if (!this.sid || !this.token || !params.callerPhone || !params.recipientPhone) {
      return {
        provider: this.name,
        call_sid: `exotel_fallback_${Date.now()}`,
        status: 'initiated',
        proxy_display: `+91 ${this.callerId} (Exotel Proxy)`,
        is_demo: true,
        notes: 'Exotel credentials not configured; running in fallback demo mode',
      };
    }

    try {
      const url = `https://${this.subdomain}/v1/Accounts/${this.sid}/Calls/connect.json`;
      const auth = btoa(`${this.sid}:${this.token}`);
      const body = new URLSearchParams({
        From: params.callerPhone,
        To: params.recipientPhone,
        CallerId: this.callerId,
        CallType: 'trans',
      });

      const res = await fetch(url, {
        method: 'POST',
        headers: {
          Authorization: `Basic ${auth}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body.toString(),
      });

      if (!res.ok) {
        return {
          provider: this.name,
          call_sid: `exotel_err_${Date.now()}`,
          status: 'failed',
          proxy_display: `+91 ${this.callerId} (Exotel Proxy)`,
          is_demo: false,
          notes: `Exotel call request failed: ${res.statusText}`,
        };
      }

      const data = await res.json();
      return {
        provider: this.name,
        call_sid: data?.Call?.Sid || `exotel_${Date.now()}`,
        status: 'connected',
        proxy_display: `+91 ${this.callerId} (Exotel Proxy)`,
        is_demo: false,
      };
    } catch (e: any) {
      return {
        provider: this.name,
        call_sid: `exotel_exc_${Date.now()}`,
        status: 'failed',
        proxy_display: `+91 ${this.callerId} (Exotel Proxy)`,
        is_demo: false,
        notes: `Exotel exception: ${e.message}`,
      };
    }
  }

  async endCall(params: EndCallParams): Promise<EndCallResult> {
    return {
      ok: true,
      status: 'completed',
      durationSeconds: params.durationSeconds || 0,
    };
  }
}

/**
 * Returns the configured call provider instance.
 */
export function getCallProvider(): CallProvider {
  const configured = (Deno.env.get('CALL_PROVIDER') || 'mock').toLowerCase();
  if (configured === 'twilio') {
    return new TwilioCallProvider();
  }
  if (configured === 'exotel') {
    return new ExotelCallProvider();
  }
  return new MockCallProvider();
}
