import { logError, logInfo } from '../../_shared/logger.ts';
import { circuitBreakers } from '../circuit_breaker.ts';

export class DeepgramProvider {
  private static getApiKey(): string | undefined {
    return Deno.env.get('DEEPGRAM_API_KEY');
  }

  static isConfigured(): boolean {
    const key = this.getApiKey();
    return !!key && key.trim().length > 0;
  }

  /**
   * Synthesize text to natural-sounding speech using Deepgram Aura.
   */
  static async synthesizeSpeech(
    text: string,
    options?: { voice?: string; language?: string },
  ): Promise<{ audioBase64: string; mimeType: string }> {
    const apiKey = this.getApiKey();
    if (!apiKey) {
      throw new Error('DEEPGRAM_API_KEY not configured');
    }

    if (!circuitBreakers.isAvailable('deepgram')) {
      throw new Error('Deepgram circuit breaker is OPEN');
    }

    const cleanLang = (options?.language || 'en').toLowerCase().substring(0, 2);
    if (cleanLang !== 'en') {
      throw new Error(`Deepgram Aura TTS only supports English ('en'). Requested language '${cleanLang}'. Regional Indic languages must use device TTS.`);
    }

    // Default to natural Aura Asteria (female, clear, friendly)
    const voiceModel = options?.voice || 'aura-asteria-en';
    const url = `https://api.deepgram.com/v1/speak?model=${encodeURIComponent(voiceModel)}`;

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 12000);

    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: {
          'Authorization': `Token ${apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ text }),
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!res.ok) {
        const errText = await res.text().catch(() => '');
        circuitBreakers.recordFailure('deepgram');
        throw new Error(`Deepgram TTS failed [${res.status}]: ${errText}`);
      }

      const mimeType = res.headers.get('content-type') || 'audio/mp3';
      const arrayBuffer = await res.arrayBuffer();
      const uint8Array = new Uint8Array(arrayBuffer);
      
      // Convert buffer to Base64 in chunks to avoid call stack limits
      let binary = '';
      const chunkSize = 8192;
      for (let i = 0; i < uint8Array.length; i += chunkSize) {
        const chunk = uint8Array.subarray(i, i + chunkSize);
        binary += String.fromCharCode(...chunk);
      }
      const audioBase64 = btoa(binary);

      circuitBreakers.recordSuccess('deepgram');
      logInfo('deepgram_tts_success', { voiceModel, bytes: uint8Array.length });
      return { audioBase64, mimeType };
    } catch (err) {
      clearTimeout(timeoutId);
      circuitBreakers.recordFailure('deepgram');
      logError('deepgram_tts_error', err);
      throw err;
    }
  }

  static isLanguageSupported(languageCode: string): boolean {
    const clean = languageCode.toLowerCase().substring(0, 2);
    return clean === 'en' || clean === 'hi';
  }

  /**
   * Transcribe speech audio to text using Deepgram Nova-2.
   * Note: Deepgram Nova-2 officially supports English ('en') and Hindi ('hi').
   * Regional Indic languages (kn, te, ta, mr, bn, or) must be routed to Groq Whisper or Gemini.
   */
  static async transcribeAudio(
    audioBytes: Uint8Array,
    mimeType: string = 'audio/wav',
    languageCode: string = 'en',
  ): Promise<{ transcript: string; confidence: number }> {
    const apiKey = this.getApiKey();
    if (!apiKey) {
      throw new Error('DEEPGRAM_API_KEY not configured');
    }

    if (!circuitBreakers.isAvailable('deepgram')) {
      throw new Error('Deepgram circuit breaker is OPEN');
    }

    const clean = languageCode.toLowerCase().substring(0, 2);
    if (!this.isLanguageSupported(clean)) {
      throw new Error(`Deepgram Nova-2 STT does not support language '${clean}'. Supported: 'en', 'hi'.`);
    }

    const lang = clean === 'hi' ? 'hi' : 'en';
    const url = `https://api.deepgram.com/v1/listen?model=nova-2&smart_format=true&language=${lang}`;

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 12000);

    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: {
          'Authorization': `Token ${apiKey}`,
          'Content-Type': mimeType,
        },
        body: audioBytes.buffer as ArrayBuffer,
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!res.ok) {
        const errText = await res.text().catch(() => '');
        circuitBreakers.recordFailure('deepgram');
        throw new Error(`Deepgram STT failed [${res.status}]: ${errText}`);
      }

      const data = await res.json();
      const alt = data?.results?.channels?.[0]?.alternatives?.[0];
      const transcript = alt?.transcript?.trim() || '';
      const confidence = alt?.confidence || 0.0;

      circuitBreakers.recordSuccess('deepgram');
      logInfo('deepgram_stt_success', { transcriptLength: transcript.length, confidence });
      return { transcript, confidence };
    } catch (err) {
      clearTimeout(timeoutId);
      circuitBreakers.recordFailure('deepgram');
      logError('deepgram_stt_error', err);
      throw err;
    }
  }
}
