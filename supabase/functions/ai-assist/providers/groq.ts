import { logError, logInfo } from '../../_shared/logger.ts';
import { circuitBreakers } from '../circuit_breaker.ts';

export class GroqProvider {
  private static getApiKey(): string | undefined {
    return Deno.env.get('GROQ_API_KEY');
  }

  static getModel(): string {
    return Deno.env.get('GROQ_MODEL') || 'llama-3.3-70b-versatile';
  }

  static isConfigured(): boolean {
    const key = this.getApiKey();
    return !!key && key.trim().length > 0;
  }

  /**
   * Fast chat completion with Groq LLM.
   */
  static async completeChat(
    systemPrompt: string,
    userMessage: string,
    options?: {
      conversationHistory?: Array<{ role: 'user' | 'assistant'; text: string }>;
      requireJson?: boolean;
      temperature?: number;
      maxTokens?: number;
    },
  ): Promise<{ content: string; parsedJson?: Record<string, unknown>; model: string }> {
    const apiKey = this.getApiKey();
    if (!apiKey) {
      throw new Error('GROQ_API_KEY not configured');
    }

    if (!circuitBreakers.isAvailable('groq')) {
      throw new Error('Groq circuit breaker is OPEN');
    }

    const model = this.getModel();
    const url = 'https://api.groq.com/openai/v1/chat/completions';

    const messages: Array<{ role: string; content: string }> = [
      { role: 'system', content: systemPrompt },
    ];

    if (options?.conversationHistory && Array.isArray(options.conversationHistory)) {
      for (const item of options.conversationHistory.slice(-6)) {
        messages.push({
          role: item.role === 'assistant' ? 'assistant' : 'user',
          content: item.text,
        });
      }
    }

    messages.push({ role: 'user', content: userMessage });

    const bodyPayload: Record<string, unknown> = {
      model,
      messages,
      temperature: options?.temperature ?? 0.2,
      max_tokens: options?.maxTokens ?? 1024,
    };

    if (options?.requireJson) {
      bodyPayload.response_format = { type: 'json_object' };
    }

    let attempt = 0;
    let lastError: string | null = null;

    while (attempt < 2) {
      attempt++;
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 9000); // 9s timeout

      try {
        const res = await fetch(url, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${apiKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(bodyPayload),
          signal: controller.signal,
        });

        clearTimeout(timeoutId);

        if (!res.ok) {
          const errText = await res.text().catch(() => '');
          lastError = `Status ${res.status}: ${errText}`;
          if (attempt === 1 && (res.status === 429 || res.status >= 500)) {
            await new Promise((r) => setTimeout(r, 600));
            continue;
          }
          circuitBreakers.recordFailure('groq');
          throw new Error(`Groq API error [${res.status}]: ${errText}`);
        }

        const data = await res.json();
        const content = data?.choices?.[0]?.message?.content?.trim() || '';

        let parsedJson: Record<string, unknown> | undefined;
        if (options?.requireJson && content) {
          try {
            parsedJson = JSON.parse(content);
          } catch {
            // Attempt to extract JSON if surrounded by markdown code blocks
            const match = content.match(/\{[\s\S]*\}/);
            if (match) {
              parsedJson = JSON.parse(match[0]);
            }
          }
        }

        circuitBreakers.recordSuccess('groq');
        logInfo('groq_chat_success', { model, length: content.length });
        return { content, parsedJson, model };
      } catch (err) {
        clearTimeout(timeoutId);
        if (attempt >= 2) {
          circuitBreakers.recordFailure('groq');
          logError('groq_chat_error', { err: String(err), lastError });
          throw err;
        }
      }
    }

    circuitBreakers.recordFailure('groq');
    throw new Error(`Groq failed after retries: ${lastError}`);
  }

  /**
   * Transcribe multilingual speech audio using Groq Whisper (whisper-large-v3-turbo).
   * Native high-accuracy support for: en, hi, kn, te, ta, mr, bn, or, and other Indic languages.
   */
  static async transcribeAudio(
    audioBytes: Uint8Array,
    mimeType: string = 'audio/wav',
    languageCode?: string,
  ): Promise<{ transcript: string; confidence: number }> {
    const apiKey = this.getApiKey();
    if (!apiKey) {
      throw new Error('GROQ_API_KEY not configured');
    }

    if (!circuitBreakers.isAvailable('groq')) {
      throw new Error('Groq circuit breaker is OPEN');
    }

    const url = 'https://api.groq.com/openai/v1/audio/transcriptions';
    const ext = mimeType.includes('mp4') || mimeType.includes('m4a') ? 'm4a' : mimeType.includes('mp3') ? 'mp3' : 'wav';
    const blob = new Blob([audioBytes.buffer as ArrayBuffer], { type: mimeType });
    const formData = new FormData();
    formData.append('file', blob, `audio.${ext}`);
    formData.append('model', 'whisper-large-v3-turbo');

    if (languageCode) {
      const cleanLang = languageCode.toLowerCase().substring(0, 2);
      formData.append('language', cleanLang);
    }
    formData.append('response_format', 'json');

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 12000);

    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${apiKey}`,
        },
        body: formData,
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!res.ok) {
        const errText = await res.text().catch(() => '');
        circuitBreakers.recordFailure('groq');
        throw new Error(`Groq Whisper STT failed [${res.status}]: ${errText}`);
      }

      const data = await res.json();
      const transcript = (data?.text || '').trim();

      circuitBreakers.recordSuccess('groq');
      logInfo('groq_stt_success', { transcriptLength: transcript.length, language: languageCode });
      return { transcript, confidence: 0.95 };
    } catch (err) {
      clearTimeout(timeoutId);
      circuitBreakers.recordFailure('groq');
      logError('groq_stt_error', err);
      throw err;
    }
  }
}

