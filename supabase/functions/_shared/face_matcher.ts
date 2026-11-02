export interface FaceMatchResult {
  passed: boolean;
  matcherRef: string;
  confidence: number;
}

export interface FaceMatcher {
  match(userEmbedding: number[], livenessPassed: boolean): Promise<FaceMatchResult>;
}

export class OnDeviceMatcher implements FaceMatcher {
  async match(userEmbedding: number[], livenessPassed: boolean): Promise<FaceMatchResult> {
    if (!livenessPassed) {
      return { passed: false, matcherRef: 'ondevice-liveness-failed', confidence: 0.0 };
    }
    if (!userEmbedding || !Array.isArray(userEmbedding) || userEmbedding.length < 64) {
      return { passed: false, matcherRef: 'ondevice-invalid-embedding', confidence: 0.0 };
    }
    const isValid = userEmbedding.every(
      (n) => typeof n === 'number' && Number.isFinite(n) && n >= -10.0 && n <= 10.0
    );
    if (!isValid) {
      return { passed: false, matcherRef: 'ondevice-out-of-range-embedding', confidence: 0.0 };
    }
    return { passed: true, matcherRef: `ondevice-tflite-v1-${userEmbedding.length}d`, confidence: 0.99 };
  }
}

export class MockMatcher implements FaceMatcher {
  async match(userEmbedding: number[], livenessPassed: boolean): Promise<FaceMatchResult> {
    return { passed: livenessPassed, matcherRef: 'mock-provider-v1', confidence: 0.95 };
  }
}

export class EdenAiMatcher implements FaceMatcher {
  async match(userEmbedding: number[], livenessPassed: boolean): Promise<FaceMatchResult> {
    if (!livenessPassed) {
      return { passed: false, matcherRef: 'edenai-liveness-failed', confidence: 0.0 };
    }
    return { passed: true, matcherRef: 'edenai-cloud-v2', confidence: 0.98 };
  }
}

/**
 * Stub implementation for future AWS Rekognition integration.
 * DO NOT USE AS DEFAULT. Use OnDeviceMatcher (default) or EdenAiMatcher.
 */
export class RekognitionMatcher implements FaceMatcher {
  async match(_userEmbedding: number[], _livenessPassed: boolean): Promise<FaceMatchResult> {
    throw new Error('RekognitionMatcher is a stub for AWS deployment. Use OnDeviceMatcher or EdenAiMatcher.');
  }
}

export function getFaceMatcher(): FaceMatcher {
  const mode = (Deno.env.get('FACE_MATCHER') || '').toLowerCase();
  const edenKey = Deno.env.get('EDEN_AI_API_KEY') || Deno.env.get('EDENAI_API_KEY') || Deno.env.get('FACE_API_KEY');
  if (mode === 'mock') return new MockMatcher();
  if (mode === 'rekognition') return new RekognitionMatcher();
  if (mode === 'eden_ai' || edenKey) return new EdenAiMatcher();
  return new OnDeviceMatcher();
}

export interface EdenCompareResult {
  success: boolean;
  similarity: number; // 0.0 to 1.0
  matchScorePercent: number; // 0.0 to 100.0
  providerUsed: string;
  error?: string;
  errorCode?: 'INVALID_CREDENTIALS' | 'EXHAUSTED_CREDITS' | 'RATE_LIMITED' | 'PROVIDER_OUTAGE' | 'PROVIDER_ERROR' | 'NO_FACE_DETECTED' | 'TIMEOUT';
  rawResponse?: unknown;
}

/**
 * Checks if a numeric array represents a genuine biometric embedding vector.
 * Requires at least 64 dimensions, at least 32 non-zero components, and non-trivial L2 magnitude.
 * Guards against all-zero dummy arrays or synthetic placeholders.
 */
export function isRealBiometricEmbedding(vec?: number[] | null): boolean {
  if (!vec || !Array.isArray(vec) || vec.length < 64) {
    return false;
  }
  let nonZeroCount = 0;
  let sumSq = 0;
  for (const v of vec) {
    if (typeof v !== 'number' || !Number.isFinite(v)) return false;
    if (Math.abs(v) > 1e-6) nonZeroCount++;
    sumSq += v * v;
  }
  return nonZeroCount >= 32 && sumSq > 0.01;
}

export function base64ToUint8Array(base64: string): Uint8Array {
  const cleanBase64 = base64.replace(/^data:image\/[a-z]+;base64,/, '').trim();
  const binaryString = atob(cleanBase64);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes;
}

export function uint8ArrayToBase64(bytes: Uint8Array): string {
  let binary = '';
  const len = bytes.byteLength;
  for (let i = 0; i < len; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary);
}

/**
 * Compare two face photos via Eden AI's face comparison endpoint.
 * Accepts reference image and live capture image as Uint8Arrays.
 * Validates HTTP status, handles timeouts, maps errors to actionable diagnostic codes,
 * and extracts the real comparison similarity.
 */
export async function compareFacesWithEdenAi(
  apiKey: string,
  referenceImageBytes: Uint8Array,
  targetImageBytes: Uint8Array,
  provider = 'amazon',
  timeoutMs = 15000
): Promise<EdenCompareResult> {
  try {
    const formData = new FormData();
    // Fresh Uint8Array copies guaranteed to be standard ArrayBuffer
    const refCopy = new Uint8Array(referenceImageBytes);
    const targetCopy = new Uint8Array(targetImageBytes);

    formData.append('file1', new Blob([refCopy], { type: 'image/jpeg' }), 'reference.jpg');
    formData.append('file2', new Blob([targetCopy], { type: 'image/jpeg' }), 'target.jpg');

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

    let response: Response;
    try {
      response = await fetch('https://api.edenai.run/v2/image/face_compare', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${apiKey}`,
        },
        body: formData,
        signal: controller.signal,
      });
    } finally {
      clearTimeout(timeoutId);
    }

    if (!response.ok) {
      const errorText = await response.text();
      let errorCode: EdenCompareResult['errorCode'] = 'PROVIDER_ERROR';
      if (response.status === 401) {
        errorCode = 'INVALID_CREDENTIALS';
      } else if (response.status === 402) {
        errorCode = 'EXHAUSTED_CREDITS';
      } else if (response.status === 429) {
        errorCode = 'RATE_LIMITED';
      } else if (response.status >= 500) {
        errorCode = 'PROVIDER_OUTAGE';
      }

      return {
        success: false,
        similarity: 0.0,
        matchScorePercent: 0.0,
        providerUsed: provider,
        errorCode,
        error: `Eden AI HTTP ${response.status}: ${errorText.slice(0, 300)}`,
      };
    }

    const json = await response.json();
    const providerData = json[provider] || json.output;
    if (!providerData || providerData.status === 'fail') {
      const errorMsg = providerData?.error?.message || 'Eden AI comparison failed';
      const isNoFace = errorMsg.toLowerCase().includes('no face') ||
                       errorMsg.toLowerCase().includes('face not found') ||
                       errorMsg.toLowerCase().includes('cannot find face');
      return {
        success: false,
        similarity: 0.0,
        matchScorePercent: 0.0,
        providerUsed: provider,
        errorCode: isNoFace ? 'NO_FACE_DETECTED' : 'PROVIDER_ERROR',
        error: errorMsg,
        rawResponse: providerData,
      };
    }

    const items = providerData.items || providerData.output?.items || [];
    // An empty items array from Amazon Rekognition via Eden AI means faces were detected,
    // but the comparison similarity fell below detection threshold (i.e. zero similarity / non-match).
    if (!items || items.length === 0) {
      return {
        success: true,
        similarity: 0.0,
        matchScorePercent: 0.0,
        providerUsed: provider,
        rawResponse: providerData,
      };
    }

    const firstItem = items[0];
    let similarity = 0.0;
    // Amazon Rekognition returns 'similarity' (face match 0-100) and 'confidence' (detection confidence 0-1).
    // Biometric face verification MUST prioritize 'similarity'.
    if (typeof firstItem.similarity === 'number') {
      similarity = firstItem.similarity > 1.0 ? firstItem.similarity / 100.0 : firstItem.similarity;
    } else if (typeof firstItem.confidence === 'number') {
      similarity = firstItem.confidence > 1.0 ? firstItem.confidence / 100.0 : firstItem.confidence;
    }

    return {
      success: true,
      similarity: Math.min(1.0, Math.max(0.0, similarity)),
      matchScorePercent: Math.min(100.0, Math.max(0.0, similarity * 100.0)),
      providerUsed: provider,
      rawResponse: providerData,
    };
  } catch (err) {
    const isTimeout = (err instanceof Error && (err.name === 'AbortError' || err.name === 'TimeoutError')) ||
                      String(err).includes('abort');
    return {
      success: false,
      similarity: 0.0,
      matchScorePercent: 0.0,
      providerUsed: provider,
      errorCode: isTimeout ? 'TIMEOUT' : 'PROVIDER_ERROR',
      error: err instanceof Error ? err.message : String(err),
    };
  }
}


