import { assertEquals } from 'jsr:@std/assert';
import {
  isRealBiometricEmbedding,
  base64ToUint8Array,
  uint8ArrayToBase64,
  compareFacesWithEdenAi,
} from '../_shared/face_matcher.ts';

Deno.test('isRealBiometricEmbedding - accepts valid float32 vectors', () => {
  // 128-d normalized vector with varying non-zero values
  const validVector = Array.from({ length: 128 }, (_, i) => Math.sin(i + 1) * 0.1);
  assertEquals(isRealBiometricEmbedding(validVector), true);
});

Deno.test('isRealBiometricEmbedding - rejects dummy and all-zero vectors', () => {
  // All zeros
  const allZeros = Array.from({ length: 128 }, () => 0.0);
  assertEquals(isRealBiometricEmbedding(allZeros), false);

  // Too short (< 64 dimensions)
  const shortVector = [0.1, 0.2, 0.3];
  assertEquals(isRealBiometricEmbedding(shortVector), false);

  // Null / undefined / empty
  assertEquals(isRealBiometricEmbedding(null), false);
  assertEquals(isRealBiometricEmbedding(undefined), false);
  assertEquals(isRealBiometricEmbedding([]), false);

  // Vector with only 1 non-zero value
  const mostlyZero = Array.from({ length: 128 }, () => 0.0);
  mostlyZero[0] = 1.0;
  assertEquals(isRealBiometricEmbedding(mostlyZero), false);
});

Deno.test('base64 <-> uint8Array round trip conversion', () => {
  const originalBytes = new Uint8Array([10, 20, 30, 40, 50, 60, 70, 80]);
  const base64Str = uint8ArrayToBase64(originalBytes);
  const recoveredBytes = base64ToUint8Array(base64Str);

  assertEquals(recoveredBytes.length, originalBytes.length);
  for (let i = 0; i < originalBytes.length; i++) {
    assertEquals(recoveredBytes[i], originalBytes[i]);
  }
});

Deno.test('compareFacesWithEdenAi - correctly parses successful Amazon Rekognition similarity', async () => {
  const originalFetch = globalThis.fetch;
  try {
    globalThis.fetch = async () =>
      new Response(
        JSON.stringify({
          amazon: {
            status: 'success',
            items: [
              {
                confidence: 0.9999,
                similarity: 98.7,
                bounding_box: { top: 0.1, left: 0.2, width: 0.5, height: 0.5 },
              },
            ],
            cost: 0.001,
          },
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );

    const ref = new Uint8Array([1, 2, 3]);
    const live = new Uint8Array([4, 5, 6]);
    const result = await compareFacesWithEdenAi('test-key', ref, live, 'amazon');

    assertEquals(result.success, true);
    assertEquals(Math.abs(result.similarity - 0.987) < 0.0001, true);
    assertEquals(result.matchScorePercent, 98.7);
    assertEquals(result.providerUsed, 'amazon');
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test('compareFacesWithEdenAi - correctly treats empty items array as non-match (similarity: 0.0)', async () => {
  const originalFetch = globalThis.fetch;
  try {
    globalThis.fetch = async () =>
      new Response(
        JSON.stringify({
          amazon: {
            status: 'success',
            items: [],
            cost: 0.001,
          },
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );

    const ref = new Uint8Array([1, 2, 3]);
    const live = new Uint8Array([4, 5, 6]);
    const result = await compareFacesWithEdenAi('test-key', ref, live, 'amazon');

    assertEquals(result.success, true);
    assertEquals(result.similarity, 0.0);
    assertEquals(result.matchScorePercent, 0.0);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test('compareFacesWithEdenAi - classifies HTTP 402 as EXHAUSTED_CREDITS', async () => {
  const originalFetch = globalThis.fetch;
  try {
    globalThis.fetch = async () =>
      new Response(
        JSON.stringify({ message: "You don't have enough credits to perform this request" }),
        { status: 402, headers: { 'Content-Type': 'application/json' } }
      );

    const ref = new Uint8Array([1, 2, 3]);
    const live = new Uint8Array([4, 5, 6]);
    const result = await compareFacesWithEdenAi('test-key', ref, live, 'amazon');

    assertEquals(result.success, false);
    assertEquals(result.errorCode, 'EXHAUSTED_CREDITS');
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test('compareFacesWithEdenAi - classifies no face found error as NO_FACE_DETECTED', async () => {
  const originalFetch = globalThis.fetch;
  try {
    globalThis.fetch = async () =>
      new Response(
        JSON.stringify({
          amazon: {
            status: 'fail',
            error: { message: 'Cannot find face in target image' },
          },
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );

    const ref = new Uint8Array([1, 2, 3]);
    const live = new Uint8Array([4, 5, 6]);
    const result = await compareFacesWithEdenAi('test-key', ref, live, 'amazon');

    assertEquals(result.success, false);
    assertEquals(result.errorCode, 'NO_FACE_DETECTED');
  } finally {
    globalThis.fetch = originalFetch;
  }
});

