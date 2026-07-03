// Kärnan i chat-proxyn — ren funktion med injicerbar fetch (testbar utan nätverk).
// Loggar ALDRIG API-nyckeln (eller dess längd).

import { SYSTEM_PROMPT } from '../_system-prompt';
import type { Env, FetchLike } from './types';

export const MAX_MESSAGES = 40;
export const MAX_TOTAL_CHARS = 100_000;
export const MAX_CANVAS_CHARS = 30_000;
export const DEFAULT_MODEL = 'claude-opus-4-8';

const ANTHROPIC_URL = 'https://api.anthropic.com/v1/messages';
const JSON_HEADERS = { 'content-type': 'application/json' };

interface ChatMessage {
  role: 'user' | 'assistant';
  content: string;
}

function jsonError(status: number, error: string): Response {
  return new Response(JSON.stringify({ error }), { status, headers: JSON_HEADERS });
}

/** Sanera klientens meddelanden: ENDAST {role, content}-strängar släpps igenom. */
function sanitizeMessages(raw: unknown): ChatMessage[] | null {
  if (!Array.isArray(raw) || raw.length === 0) return null;
  const out: ChatMessage[] = [];
  for (const m of raw) {
    if (typeof m !== 'object' || m === null) return null;
    const { role, content } = m as Record<string, unknown>;
    if (role !== 'user' && role !== 'assistant') return null;
    if (typeof content !== 'string') return null;
    out.push({ role, content });
  }
  return out;
}

function accessCodeOk(code: unknown, env: Env): boolean {
  if (typeof code !== 'string' || code.length === 0) return false;
  const valid = (env.ACCESS_CODES ?? '')
    .split(',')
    .map((c) => c.trim())
    .filter((c) => c.length > 0);
  return valid.includes(code.trim());
}

function buildSystem(canvasMermaid: unknown): string {
  if (typeof canvasMermaid !== 'string' || canvasMermaid.trim().length === 0) return SYSTEM_PROMPT;
  const canvas = canvasMermaid.slice(0, MAX_CANVAS_CHARS);
  return `${SYSTEM_PROMPT}\n\nNuvarande canvas (mermaid):\n\`\`\`mermaid\n${canvas}\n\`\`\``;
}

export async function handleChat(request: Request, env: Env, fetchImpl: FetchLike): Promise<Response> {
  let body: Record<string, unknown>;
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return jsonError(400, 'ogiltig JSON');
  }

  if (!accessCodeOk(body.accessCode, env)) return jsonError(401, 'fel åtkomstkod');

  const messages = sanitizeMessages(body.messages);
  if (!messages) return jsonError(400, 'ogiltiga meddelanden');
  if (messages.length > MAX_MESSAGES) return jsonError(400, `för många meddelanden (max ${MAX_MESSAGES})`);

  const totalChars = messages.reduce((sum, m) => sum + m.content.length, 0);
  if (totalChars > MAX_TOTAL_CHARS) return jsonError(400, `för lång konversation (max ${MAX_TOTAL_CHARS} tecken)`);

  const upstream = await fetchImpl(ANTHROPIC_URL, {
    method: 'POST',
    headers: {
      'x-api-key': env.ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: env.AI_MODEL || DEFAULT_MODEL,
      max_tokens: 4096,
      stream: true,
      system: buildSystem(body.canvasMermaid),
      messages,
    }),
  });

  if (!upstream.ok) {
    // Skicka vidare uppströms felmeddelande (aldrig nyckeln) med samma status.
    let message = 'AI-tjänsten svarade med fel';
    try {
      const err = (await upstream.json()) as { error?: { message?: string } };
      if (err.error?.message) message = err.error.message;
    } catch {
      // icke-JSON-fel → generiskt meddelande
    }
    return jsonError(upstream.status, message);
  }

  return new Response(upstream.body, {
    headers: { 'content-type': 'text/event-stream', 'cache-control': 'no-cache' },
  });
}
