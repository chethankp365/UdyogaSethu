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

/**
 * Stub implementation for future AWS Rekognition integration.
 * DO NOT USE AS DEFAULT. Use OnDeviceMatcher (default) or MockMatcher.
 */
export class RekognitionMatcher implements FaceMatcher {
  async match(_userEmbedding: number[], _livenessPassed: boolean): Promise<FaceMatchResult> {
    throw new Error('RekognitionMatcher is a stub for AWS deployment. Use OnDeviceMatcher.');
  }
}

export function getFaceMatcher(): FaceMatcher {
  const mode = (Deno.env.get('FACE_MATCHER') || 'ondevice').toLowerCase();
  if (mode === 'mock') return new MockMatcher();
  if (mode === 'rekognition') return new RekognitionMatcher();
  return new OnDeviceMatcher();
}
