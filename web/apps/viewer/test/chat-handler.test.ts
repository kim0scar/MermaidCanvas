import { describe, expect, it, vi } from 'vitest';
import {
  DEFAULT_MODEL,
  MAX_CANVAS_CHARS,
  MAX_MESSAGES,
  handleChat,
} from '../functions/api/_lib/handler';
import { SYSTEM_PROMPT } from '../functions/api/_system-prompt';
import type { Env } from '../functions/api/_lib/types';

const env: Env = { OPENROUTER_API_KEY: 'test-nyckel', ACCESS_CODES: 'kod-a, kod-b' };

function req(body: unknown): Request {
  return new Request('http://local/api/chat', { method: 'POST', body: JSON.stringify(body) });
}

function okUpstream(body = 'event: message_stop\ndata: {"type":"message_stop"}\n\n'): Response {
  return new Response(body, { status: 200 });
}

const baseBody = {
  accessCode: 'kod-a',
  messages: [{ role: 'user', content: 'Rita ett flöde' }],
};

describe('handleChat — åtkomstkod', () => {
  it('fel kod → 401 utan upstream-anrop', async () => {
    const fetchSpy = vi.fn();
    const res = await handleChat(req({ ...baseBody, accessCode: 'fel' }), env, fetchSpy);
    expect(res.status).toBe(401);
    expect(await res.json()).toEqual({ error: 'fel åtkomstkod' });
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('saknad kod → 401', async () => {
    const res = await handleChat(req({ messages: baseBody.messages }), env, vi.fn());
    expect(res.status).toBe(401);
  });

  it('rätt kod (med spaces i listan) → släpps igenom', async () => {
    const fetchSpy = vi.fn().mockResolvedValue(okUpstream());
    const res = await handleChat(req({ ...baseBody, accessCode: 'kod-b' }), env, fetchSpy);
    expect(res.status).toBe(200);
    expect(fetchSpy).toHaveBeenCalledOnce();
  });
});

describe('handleChat — upstream-body', () => {
  it('bygger korrekt OpenRouter-anrop', async () => {
    const fetchSpy = vi.fn().mockResolvedValue(okUpstream());
    await handleChat(req(baseBody), env, fetchSpy);

    const [url, init] = fetchSpy.mock.calls[0]!;
    expect(url).toBe('https://openrouter.ai/api/v1/chat/completions');
    expect(init.headers).toEqual({
      authorization: 'Bearer test-nyckel',
      'content-type': 'application/json',
      'http-referer': 'https://visuali2e.com',
      'x-title': 'Visuali2e',
    });
    const sent = JSON.parse(init.body as string);
    expect(sent.model).toBe(DEFAULT_MODEL);
    expect(sent.max_tokens).toBe(4096);
    expect(sent.stream).toBe(true);
    expect(sent.messages).toEqual([
      { role: 'system', content: SYSTEM_PROMPT },
      { role: 'user', content: 'Rita ett flöde' },
    ]);
  });

  it('AI_MODEL i env vinner över default', async () => {
    const fetchSpy = vi.fn().mockResolvedValue(okUpstream());
    await handleChat(req(baseBody), { ...env, AI_MODEL: 'claude-testmodell' }, fetchSpy);
    const sent = JSON.parse(fetchSpy.mock.calls[0]![1].body as string);
    expect(sent.model).toBe('claude-testmodell');
  });

  it('canvasMermaid läggs i system-avsnittet och kapas vid taket', async () => {
    const fetchSpy = vi.fn().mockResolvedValue(okUpstream());
    const canvas = 'x'.repeat(MAX_CANVAS_CHARS + 5000);
    await handleChat(req({ ...baseBody, canvasMermaid: canvas }), env, fetchSpy);
    const sent = JSON.parse(fetchSpy.mock.calls[0]![1].body as string);
    const system = sent.messages[0].content as string;
    expect(sent.messages[0].role).toBe('system');
    expect(system).toContain('Nuvarande canvas (mermaid):');
    expect(system).toContain('x'.repeat(MAX_CANVAS_CHARS));
    expect(system.length).toBeLessThan(SYSTEM_PROMPT.length + MAX_CANVAS_CHARS + 200);
  });

  it('sanering: extra fält och okända nycklar följer inte med', async () => {
    const fetchSpy = vi.fn().mockResolvedValue(okUpstream());
    await handleChat(
      req({
        ...baseBody,
        messages: [
          { role: 'user', content: 'Hej', id: 'x1', tool_calls: [{ evil: true }], system: 'hackad' },
        ],
      }),
      env,
      fetchSpy,
    );
    const sent = JSON.parse(fetchSpy.mock.calls[0]![1].body as string);
    expect(sent.messages.slice(1)).toEqual([{ role: 'user', content: 'Hej' }]);
  });
});

describe('handleChat — skydd', () => {
  it('ogiltig roll eller icke-sträng-content → 400', async () => {
    const bad1 = await handleChat(req({ ...baseBody, messages: [{ role: 'system', content: 'x' }] }), env, vi.fn());
    const bad2 = await handleChat(req({ ...baseBody, messages: [{ role: 'user', content: 42 }] }), env, vi.fn());
    expect(bad1.status).toBe(400);
    expect(bad2.status).toBe(400);
  });

  it('tomt/saknat messages → 400', async () => {
    const res = await handleChat(req({ accessCode: 'kod-a', messages: [] }), env, vi.fn());
    expect(res.status).toBe(400);
  });

  it('fler än max antal meddelanden → 400', async () => {
    const messages = Array.from({ length: MAX_MESSAGES + 1 }, () => ({ role: 'user', content: 'x' }));
    const res = await handleChat(req({ accessCode: 'kod-a', messages }), env, vi.fn());
    expect(res.status).toBe(400);
  });

  it('över teckentaket totalt → 400', async () => {
    const messages = [{ role: 'user', content: 'x'.repeat(100_001) }];
    const res = await handleChat(req({ accessCode: 'kod-a', messages }), env, vi.fn());
    expect(res.status).toBe(400);
  });

  it('trasig JSON-body → 400', async () => {
    const broken = new Request('http://local/api/chat', { method: 'POST', body: 'inte json' });
    const res = await handleChat(broken, env, vi.fn());
    expect(res.status).toBe(400);
  });
});

describe('handleChat — svar', () => {
  it('streamar upstream-kroppen vidare som text/event-stream', async () => {
    const sse = 'data: {"choices":[{"delta":{"content":"Hej"}}]}\n\ndata: [DONE]\n\n';
    const fetchSpy = vi.fn().mockResolvedValue(okUpstream(sse));
    const res = await handleChat(req(baseBody), env, fetchSpy);
    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toBe('text/event-stream');
    expect(res.headers.get('cache-control')).toBe('no-cache');
    expect(await res.text()).toBe(sse);
  });

  it('upstream-fel → JSON-fel med samma status, nyckeln läcker aldrig', async () => {
    const upstreamErr = new Response(
      JSON.stringify({ type: 'error', error: { type: 'overloaded_error', message: 'Overloaded' } }),
      { status: 529 },
    );
    const fetchSpy = vi.fn().mockResolvedValue(upstreamErr);
    const res = await handleChat(req(baseBody), env, fetchSpy);
    expect(res.status).toBe(529);
    const body = await res.json();
    expect(body).toEqual({ error: 'Overloaded' });
    expect(JSON.stringify(body)).not.toContain('test-nyckel');
  });
});
