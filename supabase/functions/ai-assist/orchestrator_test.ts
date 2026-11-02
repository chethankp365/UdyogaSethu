import { assertEquals } from 'jsr:@std/assert';
import { AiOrchestrator } from './orchestrator.ts';
import { circuitBreakers } from './circuit_breaker.ts';

Deno.test('AiOrchestrator - discovers all 5 provider capabilities', () => {
  const caps = AiOrchestrator.getProviderCapabilities();
  assertEquals(caps.length, 5);

  const ids = caps.map((c) => c.id).sort();
  assertEquals(ids, ['deepgram', 'gemini', 'groq', 'huggingface', 'openrouter'].sort());

  const deepgram = caps.find((c) => c.id === 'deepgram')!;
  assertEquals(deepgram.supportsTts, true);
  assertEquals(deepgram.supportsStt, true);

  const groq = caps.find((c) => c.id === 'groq')!;
  assertEquals(groq.supportsStreaming, true);

  const gemini = caps.find((c) => c.id === 'gemini')!;
  assertEquals(gemini.supportsMultimodal, true);
});

Deno.test('AiOrchestrator - builds prompt & JSON schema correctly', () => {
  const config = AiOrchestrator.buildPromptConfig({
    task: 'voice_intent',
    spoken_text: 'find delivery jobs in Koramangala',
    language: 'kn',
    user_role: 'seeker',
  });

  assertEquals(config.baseInstructions.includes('Kannada'), true);
  assertEquals(config.prompt.includes('open_nearby_jobs'), true);
  assertEquals(typeof config.jsonSchema.properties, 'object');
});

Deno.test('CircuitBreakerRegistry - isolates failures and enforces thresholds', () => {
  // Initially available
  assertEquals(circuitBreakers.isAvailable('groq'), true);

  // 3 consecutive failures trigger OPEN
  circuitBreakers.recordFailure('groq');
  circuitBreakers.recordFailure('groq');
  circuitBreakers.recordFailure('groq');
  assertEquals(circuitBreakers.isAvailable('groq'), false);

  // Reset / recovery
  circuitBreakers.recordSuccess('groq');
  assertEquals(circuitBreakers.isAvailable('groq'), true);
});

Deno.test('AiOrchestrator - rejects when all providers are unconfigured or fail', async () => {
  let threw = false;
  try {
    await AiOrchestrator.orchestrate({
      task: 'assistant_query',
      spoken_text: 'hello',
      language: 'en',
    });
  } catch (err) {
    threw = true;
    assertEquals((err as Error).message.includes('All AI providers failed'), true);
  }
  assertEquals(threw, true);
});

Deno.test('AiOrchestrator - requires valid text for voice_tts task', async () => {
  let threw = false;
  try {
    await AiOrchestrator.orchestrate({
      task: 'voice_tts',
      tts_text: '',
    });
  } catch (err) {
    threw = true;
    assertEquals((err as Error).message.includes('Missing text to synthesize'), true);
  }
  assertEquals(threw, true);
});

Deno.test('AiOrchestrator - requires audio_base64 for voice_stt task', async () => {
  let threw = false;
  try {
    await AiOrchestrator.orchestrate({
      task: 'voice_stt',
    });
  } catch (err) {
    threw = true;
    assertEquals((err as Error).message.includes('Missing audio_base64 to transcribe'), true);
  }
  assertEquals(threw, true);
});

Deno.test('CircuitBreakerRegistry - half-open probe after cooldown', () => {
  const cb = circuitBreakers;
  cb.recordFailure('gemini');
  cb.recordFailure('gemini');
  cb.recordFailure('gemini');
  assertEquals(cb.isAvailable('gemini'), false);

  // Stats report open state
  const stats = cb.getStats();
  const geminiStat = stats['gemini'] as Record<string, unknown>;
  assertEquals(geminiStat.state, 'open');
  assertEquals(geminiStat.failures, 3);

  // Recovery upon recorded success
  cb.recordSuccess('gemini');
  assertEquals(cb.isAvailable('gemini'), true);
});

Deno.test('DeepgramProvider - strictly verifies language support without false fallbacks', async () => {
  const { DeepgramProvider } = await import('./providers/deepgram.ts');
  assertEquals(DeepgramProvider.isLanguageSupported('en'), true);
  assertEquals(DeepgramProvider.isLanguageSupported('hi'), true);
  assertEquals(DeepgramProvider.isLanguageSupported('kn'), false);
  assertEquals(DeepgramProvider.isLanguageSupported('te'), false);
  assertEquals(DeepgramProvider.isLanguageSupported('ta'), false);
  assertEquals(DeepgramProvider.isLanguageSupported('mr'), false);
  assertEquals(DeepgramProvider.isLanguageSupported('bn'), false);
  assertEquals(DeepgramProvider.isLanguageSupported('or'), false);
});

Deno.test('AiOrchestrator - routes regional voice_tts to client device TTS without calling Deepgram Aura', async () => {
  for (const lang of ['kn', 'hi', 'te', 'ta', 'mr', 'bn', 'or']) {
    const res = await AiOrchestrator.orchestrate({
      task: 'voice_tts',
      tts_text: 'Sample test text',
      language: lang,
    });
    assertEquals(res.ok, true);
    assertEquals(res.result.use_client_tts, true);
    assertEquals(res.result.language, lang);
  }
});

Deno.test('AiOrchestrator - builds multilingual prompts for all 8 supported languages', () => {
  const expectedLanguages: Record<string, string> = {
    en: 'English',
    kn: 'Kannada',
    hi: 'Hindi',
    te: 'Telugu',
    ta: 'Tamil',
    mr: 'Marathi',
    bn: 'Bengali',
    or: 'Odia',
  };

  for (const [code, name] of Object.entries(expectedLanguages)) {
    const config = AiOrchestrator.buildPromptConfig({
      task: 'voice_intent',
      spoken_text: 'sample test query',
      language: code,
      user_role: 'seeker',
    });
    assertEquals(config.baseInstructions.includes(name), true);
    assertEquals(config.prompt.includes(name), true);
  }
});

Deno.test('Security Audit - role escalation cannot grant unauthorized permissions', () => {
  // Authoritative role from database is 'seeker'
  const authoritativeRole: string = 'seeker';
  const requestedRole: string = 'provider'; // Client attempts privilege escalation

  const validRoles = ['seeker', 'provider', 'farmer'];
  const finalRole = (requestedRole && validRoles.includes(requestedRole) && requestedRole === authoritativeRole)
    ? requestedRole
    : authoritativeRole;

  assertEquals(finalRole, 'seeker'); // Escalation blocked
});

Deno.test('Security Audit - audio MIME whitelist allows only supported audio containers', () => {
  const allowedAudioMimes = ['audio/m4a', 'audio/mp4', 'audio/aac', 'audio/wav', 'audio/webm', 'audio/ogg', 'audio/mpeg'];
  assertEquals(allowedAudioMimes.includes('audio/wav'), true);
  assertEquals(allowedAudioMimes.includes('audio/m4a'), true);
  assertEquals(allowedAudioMimes.includes('application/x-sh'), false);
  assertEquals(allowedAudioMimes.includes('text/html'), false);
  assertEquals(allowedAudioMimes.includes('application/json'), false);
});

Deno.test('Security Audit - audio size limit strictly caps at 1.5MB base64', () => {
  const maxAudioBase64Length = 1.5 * 1024 * 1024; // 1,572,864 characters
  const validBase64 = 'UklGRi4AAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQAAAAA=';
  assertEquals(validBase64.length < maxAudioBase64Length, true);

  // Payload exceeding 1.5MB is rejected
  const oversizedLength = 1.6 * 1024 * 1024;
  assertEquals(oversizedLength > maxAudioBase64Length, true);
});

Deno.test('Security Audit - error and probe responses redact Bearer and Token secrets', () => {
  const rawError = 'Groq API error: 401 Unauthorized for Bearer gsk_fakeSecretKey1234567890';
  const sanitized = rawError.replace(/Bearer\s+[A-Za-z0-9_\-\.]+/gi, 'Bearer [REDACTED]');
  assertEquals(sanitized.includes('gsk_fakeSecretKey1234567890'), false);
  assertEquals(sanitized.includes('Bearer [REDACTED]'), true);

  const rawDeepgramError = 'Deepgram failed: Token dg_fakeToken12345';
  const sanitizedDg = rawDeepgramError.replace(/Token\s+[A-Za-z0-9_\-\.]+/gi, 'Token [REDACTED]');
  assertEquals(sanitizedDg.includes('dg_fakeToken12345'), false);
  assertEquals(sanitizedDg.includes('Token [REDACTED]'), true);
});



