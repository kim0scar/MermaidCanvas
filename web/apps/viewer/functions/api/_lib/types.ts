// Minimala lokala typer för Cloudflare Pages Functions — inga npm-beroenden.

export interface Env {
  /** Hemlighet: OpenRouter API-nyckel (Kims konto). Loggas ALDRIG. */
  OPENROUTER_API_KEY: string;
  /** Hemlighet: kommaseparerade åtkomstkoder (gate:ar kostnaden). */
  ACCESS_CODES: string;
  /** Valfri modell-override (OpenRouter-slug, t.ex. anthropic/claude-haiku-4.5). */
  AI_MODEL?: string;
}

export interface PagesContext<E> {
  request: Request;
  env: E;
}

export type PagesFunction<E> = (ctx: PagesContext<E>) => Response | Promise<Response>;

export type FetchLike = (url: string, init: RequestInit) => Promise<Response>;
