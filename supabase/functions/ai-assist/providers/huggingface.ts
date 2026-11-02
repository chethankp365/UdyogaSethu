import { logError, logInfo } from '../../_shared/logger.ts';
import { circuitBreakers } from '../circuit_breaker.ts';

export class HuggingFaceProvider {
  private static getApiKey(): string | undefined {
    return Deno.env.get('HUGGINGFACE_API_KEY') || Deno.env.get('HF_API_KEY');
  }

  static getModel(): string {
    return Deno.env.get('HUGGINGFACE_MODEL') || 'facebook/bart-large-mnli';
  }

  static isConfigured(): boolean {
    const key = this.getApiKey();
    return !!key && key.trim().length > 0;
  }

  /**
   * Classify user voice query into candidate intent categories using zero-shot classification.
   */
  static async classifyZeroShot(
    text: string,
    candidateLabels: string[],
  ): Promise<{ topLabel: string; topScore: number; scores: Record<string, number>; model: string }> {
    const apiKey = this.getApiKey();
    if (!apiKey) {
      throw new Error('HUGGINGFACE_API_KEY not configured');
    }

    if (!circuitBreakers.isAvailable('huggingface')) {
      throw new Error('Hugging Face circuit breaker is OPEN');
    }

    const model = this.getModel();
    const primaryUrl = `https://router.huggingface.co/hf-inference/models/${model}`;
    const legacyUrl = `https://api-inference.huggingface.co/models/${model}`;

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 9000); // 9s timeout

    try {
      const headers = {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        'x-wait-for-model': 'true',
      };
      const body = JSON.stringify({
        inputs: text,
        parameters: {
          candidate_labels: candidateLabels,
          multi_label: false,
        },
      });

      let res = await fetch(primaryUrl, {
        method: 'POST',
        headers,
        body,
        signal: controller.signal,
      });

      // Fallback to legacy endpoint if router returned 404
      if (res.status === 404) {
        res = await fetch(legacyUrl, {
          method: 'POST',
          headers,
          body,
          signal: controller.signal,
        });
      }

      clearTimeout(timeoutId);

      if (!res.ok) {
        const errText = await res.text().catch(() => '');
        // If model is still loading (503), do not trip circuit breaker immediately
        if (res.status !== 503) {
          circuitBreakers.recordFailure('huggingface');
        }
        throw new Error(`Hugging Face inference error [${res.status}]: ${errText}`);
      }

      const data = await res.json();
      const labels: string[] = data?.labels || [];
      const scores: number[] = data?.scores || [];

      const scoreMap: Record<string, number> = {};
      for (let i = 0; i < labels.length; i++) {
        scoreMap[labels[i]] = scores[i] ?? 0;
      }

      const topLabel = labels[0] || 'general_question';
      const topScore = scores[0] || 0.0;

      circuitBreakers.recordSuccess('huggingface');
      logInfo('huggingface_classification_success', { model, topLabel, topScore });
      return { topLabel, topScore, scores: scoreMap, model };
    } catch (err) {
      clearTimeout(timeoutId);
      circuitBreakers.recordFailure('huggingface');
      logError('huggingface_classification_error', err);
      throw err;
    }
  }
}
