import { logError, logInfo } from '../../_shared/logger.ts';
import { circuitBreakers } from '../circuit_breaker.ts';

export class OpenRouterProvider {
  private static getApiKey(): string | undefined {
    return Deno.env.get('OPENROUTER_API_KEY');
  }

  static getModel(): string {
    return Deno.env.get('OPENROUTER_MODEL') || 'meta-llama/llama-3.1-8b-instruct';
  }

  static isConfigured(): boolean {
    const key = this.getApiKey();
    return !!key && key.trim().length > 0;
  }

  /**
   * Complete chat using OpenRouter dynamic multi-model routing.
   */
  static async completeChat(
    systemPrompt: string,
    userMessage: string,
    options?: {
      conversationHistory?: Array<{ role: 'user' | 'assistant'; text: string }>;
      requireJson?: boolean;
      temperature?: number;
      maxTokens?: number;
      model?: string;
    },
  ): Promise<{ content: string; parsedJson?: Record<string, unknown>; model: string }> {
    const apiKey = this.getApiKey();
    if (!apiKey) {
      throw new Error('OPENROUTER_API_KEY not configured');
    }

    if (!circuitBreakers.isAvailable('openrouter')) {
      throw new Error('OpenRouter circuit breaker is OPEN');
    }

    const model = options?.model || this.getModel();
    const url = 'https://openrouter.ai/api/v1/chat/completions';

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
      const timeoutId = setTimeout(() => controller.abort(), 10000); // 10s timeout

      try {
        const res = await fetch(url, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${apiKey}`,
            'HTTP-Referer': 'https://udyogasethu.in',
            'X-Title': 'UdyogaSethu AI Voice Assistant',
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
          circuitBreakers.recordFailure('openrouter');
          throw new Error(`OpenRouter API error [${res.status}]: ${errText}`);
        }

        const data = await res.json();
        const content = data?.choices?.[0]?.message?.content?.trim() || '';

        let parsedJson: Record<string, unknown> | undefined;
        if (options?.requireJson && content) {
          try {
            parsedJson = JSON.parse(content);
          } catch {
            const match = content.match(/\{[\s\S]*\}/);
            if (match) {
              parsedJson = JSON.parse(match[0]);
            }
          }
        }

        circuitBreakers.recordSuccess('openrouter');
        logInfo('openrouter_chat_success', { model, length: content.length });
        return { content, parsedJson, model };
      } catch (err) {
        clearTimeout(timeoutId);
        if (attempt >= 2) {
          circuitBreakers.recordFailure('openrouter');
          logError('openrouter_chat_error', { err: String(err), lastError });
          throw err;
        }
      }
    }

    circuitBreakers.recordFailure('openrouter');
    throw new Error(`OpenRouter failed after retries: ${lastError}`);
  }
}
