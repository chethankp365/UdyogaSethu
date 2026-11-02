import { logError, logInfo } from '../../_shared/logger.ts';
import { circuitBreakers } from '../circuit_breaker.ts';

export class GeminiProvider {
  private static getApiKey(): string | undefined {
    return Deno.env.get('GEMINI_API_KEY');
  }

  static getModel(): string {
    return Deno.env.get('GEMINI_MODEL') || 'gemini-1.5-flash';
  }

  static isConfigured(): boolean {
    const key = this.getApiKey();
    return !!key && key.trim().length > 0;
  }

  /**
   * Invoke Gemini for complex reasoning and multimodal vision tasks.
   */
  static async generateContent(
    systemInstructions: string,
    prompt: string,
    options?: {
      jsonSchema?: Record<string, unknown>;
      imageBase64?: string;
      imageMime?: string;
      temperature?: number;
      maxOutputTokens?: number;
    },
  ): Promise<{ content: string; parsedJson?: Record<string, unknown>; model: string }> {
    const apiKey = this.getApiKey();
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY not configured');
    }

    if (!circuitBreakers.isAvailable('gemini')) {
      throw new Error('Gemini circuit breaker is OPEN');
    }

    const model = this.getModel();
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;

    const parts: Array<Record<string, unknown>> = [];

    // Multimodal image support
    if (options?.imageBase64) {
      let rawBase64 = options.imageBase64;
      if (rawBase64.includes(',')) {
        rawBase64 = rawBase64.split(',')[1];
      }
      parts.push({
        inlineData: {
          mimeType: options.imageMime || 'image/jpeg',
          data: rawBase64,
        },
      });
    }

    parts.push({ text: prompt });

    const requestBody: Record<string, unknown> = {
      systemInstruction: {
        parts: [{ text: systemInstructions }],
      },
      contents: [
        {
          role: 'user',
          parts,
        },
      ],
      generationConfig: {
        temperature: options?.temperature ?? 0.2,
        maxOutputTokens: options?.maxOutputTokens ?? 1024,
      },
    };

    if (options?.jsonSchema) {
      (requestBody.generationConfig as Record<string, unknown>).responseMimeType = 'application/json';
      (requestBody.generationConfig as Record<string, unknown>).responseSchema = options.jsonSchema;
    }

    let attempt = 0;
    let lastError: string | null = null;

    while (attempt < 2) {
      attempt++;
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 12000); // 12s timeout

      try {
        const res = await fetch(url, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: JSON.stringify(requestBody),
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
          circuitBreakers.recordFailure('gemini');
          throw new Error(`Gemini API error [${res.status}]: ${errText}`);
        }

        const data = await res.json();
        const content = data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || '';

        let parsedJson: Record<string, unknown> | undefined;
        if (content && (options?.jsonSchema || content.startsWith('{'))) {
          try {
            parsedJson = JSON.parse(content);
          } catch {
            const match = content.match(/\{[\s\S]*\}/);
            if (match) {
              parsedJson = JSON.parse(match[0]);
            }
          }
        }

        circuitBreakers.recordSuccess('gemini');
        logInfo('gemini_generate_success', { model, length: content.length });
        return { content, parsedJson, model };
      } catch (err) {
        clearTimeout(timeoutId);
        if (attempt >= 2) {
          circuitBreakers.recordFailure('gemini');
          logError('gemini_generate_error', { err: String(err), lastError });
          throw err;
        }
      }
    }

    circuitBreakers.recordFailure('gemini');
    throw new Error(`Gemini failed after retries: ${lastError}`);
  }

  /**
   * Multilingual audio transcription using Gemini 1.5 Flash multimodal capabilities.
   * Full native support for all 22 official Indian languages including kn, te, ta, mr, bn, or, hi, en.
   */
  static async transcribeAudio(
    audioBase64: string,
    mimeType: string = 'audio/wav',
    languageCode?: string,
  ): Promise<{ transcript: string; confidence: number }> {
    const apiKey = this.getApiKey();
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY not configured');
    }

    if (!circuitBreakers.isAvailable('gemini')) {
      throw new Error('Gemini circuit breaker is OPEN');
    }

    const model = this.getModel();
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`;

    const cleanBase64 = audioBase64.includes(',') ? audioBase64.split(',')[1] : audioBase64;
    const requestBody = {
      contents: [
        {
          role: 'user',
          parts: [
            {
              text: `Accurately transcribe the user's spoken words in their language (${languageCode || 'auto'}). Output ONLY the exact transcription text with no additional commentary, no quotes, and no metadata.`
            },
            {
              inlineData: {
                mimeType: mimeType,
                data: cleanBase64,
              }
            }
          ]
        }
      ],
      generationConfig: {
        temperature: 0.1,
        maxOutputTokens: 256,
      }
    };

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 12000);

    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: JSON.stringify(requestBody),
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!res.ok) {
        const errText = await res.text().catch(() => '');
        circuitBreakers.recordFailure('gemini');
        throw new Error(`Gemini audio transcription failed [${res.status}]: ${errText}`);
      }

      const data = await res.json();
      const transcript = (data?.candidates?.[0]?.content?.parts?.[0]?.text || '').trim();

      circuitBreakers.recordSuccess('gemini');
      logInfo('gemini_stt_success', { transcriptLength: transcript.length, language: languageCode });
      return { transcript, confidence: 0.90 };
    } catch (err) {
      clearTimeout(timeoutId);
      circuitBreakers.recordFailure('gemini');
      logError('gemini_stt_error', err);
      throw err;
    }
  }
}

