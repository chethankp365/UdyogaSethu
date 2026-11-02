import { ProviderId } from './types.ts';

interface CircuitState {
  failureCount: number;
  lastFailureTime: number;
  state: 'closed' | 'open' | 'half_open';
}

class CircuitBreakerRegistry {
  private circuits: Map<ProviderId, CircuitState> = new Map();
  private readonly failureThreshold: number = 3;
  private readonly resetTimeoutMs: number = 30000; // 30s cooldown before half_open test

  constructor() {
    const providers: ProviderId[] = ['groq', 'gemini', 'openrouter', 'deepgram', 'huggingface'];
    for (const p of providers) {
      this.circuits.set(p, {
        failureCount: 0,
        lastFailureTime: 0,
        state: 'closed',
      });
    }
  }

  isAvailable(provider: ProviderId): boolean {
    const state = this.circuits.get(provider);
    if (!state) return true;

    if (state.state === 'closed') {
      return true;
    }

    if (state.state === 'open') {
      const now = Date.now();
      if (now - state.lastFailureTime > this.resetTimeoutMs) {
        // Cooldown passed, transition to half_open for a probe
        state.state = 'half_open';
        return true;
      }
      return false; // Circuit is open, skip provider immediately
    }

    // In half_open, allow one probe request
    return true;
  }

  recordSuccess(provider: ProviderId): void {
    const state = this.circuits.get(provider);
    if (!state) return;

    state.failureCount = 0;
    state.state = 'closed';
  }

  recordFailure(provider: ProviderId): void {
    const state = this.circuits.get(provider);
    if (!state) return;

    state.failureCount += 1;
    state.lastFailureTime = Date.now();

    if (state.failureCount >= this.failureThreshold || state.state === 'half_open') {
      state.state = 'open';
    }
  }

  getStats(): Record<string, unknown> {
    const stats: Record<string, unknown> = {};
    for (const [provider, state] of this.circuits.entries()) {
      stats[provider] = {
        state: state.state,
        failures: state.failureCount,
        last_failure_ago_s: state.lastFailureTime ? Math.round((Date.now() - state.lastFailureTime) / 1000) : null,
      };
    }
    return stats;
  }
}

export const circuitBreakers = new CircuitBreakerRegistry();
