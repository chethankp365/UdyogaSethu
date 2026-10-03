// KycProvider interface and adapter implementations for eKYC (Phase 3.2)

export interface KycStartOptions {
  userId: string;
  docType: 'aadhaar' | 'pan' | 'driving_licence' | 'voter_id';
  redirectUrl: string;
}

export interface KycStartResult {
  provider: string;
  provider_ref: string;
  redirect_url: string;
  is_demo_mode: boolean;
}

export interface KycCallbackResult {
  provider_ref: string;
  doc_type: string;
  status: 'verified' | 'rejected' | 'pending';
  name_masked: string;
  masked_id: string; // Must strictly be masked, e.g. "XXXX-XXXX-1234"
  verified_at: string;
  rejection_reason?: string;
}

export interface KycProvider {
  name: string;
  startKyc(options: KycStartOptions): Promise<KycStartResult>;
  verifyCallback(payload: Record<string, unknown>): Promise<KycCallbackResult>;
}

/**
 * MockProvider: Default provider when KYC_PROVIDER=mock.
 * Returns deterministic masked results without connecting to live government APIs.
 * Guarantees 12-digit Aadhaar numbers are NEVER created or stored.
 */
export class MockProvider implements KycProvider {
  name = 'digilocker_mock';

  async startKyc(options: KycStartOptions): Promise<KycStartResult> {
    const providerRef = `mock_kyc_${options.userId.slice(0, 8)}_${Date.now()}`;
    // Construct callback URL passing provider_ref
    const redirectUrl = `${options.redirectUrl}?provider_ref=${providerRef}&status=verified`;

    return {
      provider: this.name,
      provider_ref: providerRef,
      redirect_url: redirectUrl,
      is_demo_mode: true,
    };
  }

  async verifyCallback(payload: Record<string, unknown>): Promise<KycCallbackResult> {
    const providerRef = (payload.provider_ref as String) || `mock_ref_${Date.now()}`;
    const docType = (payload.doc_type as string) || 'aadhaar';
    const status = (payload.status as 'verified' | 'rejected' | 'pending') || 'verified';

    // Mask name partially (e.g. C****** K****)
    const nameMasked = 'R***** S****';
    // Mask ID strictly as XXXX-XXXX-last4
    const maskedId = docType === 'pan' ? 'XXXXX1234X' : 'XXXX-XXXX-4321';

    return {
      provider_ref: providerRef,
      doc_type: docType,
      status: status,
      name_masked: nameMasked,
      masked_id: maskedId,
      verified_at: new Date().toISOString(),
    };
  }
}

/**
 * SandboxProvider: Connects to real DigiLocker / eKYC vendor APIs when docs are present.
 * Currently falls back to MockProvider until vendor docs are placed in docs/reference/kyc_provider_docs.md.
 */
export class SandboxProvider implements KycProvider {
  name = 'sandbox_vendor';
  private mockFallback = new MockProvider();

  // TODO(P3.2-Sandbox): Connect real vendor API when vendor docs are placed in docs/reference/kyc_provider_docs.md
  async startKyc(options: KycStartOptions): Promise<KycStartResult> {
    return this.mockFallback.startKyc(options);
  }

  async verifyCallback(payload: Record<string, unknown>): Promise<KycCallbackResult> {
    return this.mockFallback.verifyCallback(payload);
  }
}

export function getKycProvider(): KycProvider {
  const providerEnv = Deno.env.get('KYC_PROVIDER') ?? 'mock';
  if (providerEnv === 'sandbox') {
    return new SandboxProvider();
  }
  return new MockProvider();
}
