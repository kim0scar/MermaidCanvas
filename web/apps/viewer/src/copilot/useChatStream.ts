// Hook: POST /api/chat + läs Anthropics SSE-ström inkrementellt in i sista AI-meddelandet.

import { useCallback, useRef, useState } from 'react';

export interface ChatMessage {
  role: 'user' | 'assistant';
  content: string;
}

export type SendResult = 'ok' | 'unauthorized' | 'error';

interface SendArgs {
  text: string;
  accessCode: string;
  canvasMermaid?: string;
}

/** Plocka text-deltan + fel ur en Anthropic SSE-databit. */
function parseSSEData(data: string): { text?: string; error?: string } {
  try {
    const ev = JSON.parse(data) as {
      type?: string;
      delta?: { type?: string; text?: string };
      error?: { message?: string };
    };
    if (ev.type === 'content_block_delta' && ev.delta?.type === 'text_delta') {
      return { text: ev.delta.text ?? '' };
    }
    if (ev.type === 'error') return { error: ev.error?.message ?? 'okänt AI-fel' };
  } catch {
    // ofullständig/okänd rad → ignorera
  }
  return {};
}

export function useChatStream() {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [streaming, setStreaming] = useState(false);
  const [error, setError] = useState('');
  const abortRef = useRef<AbortController | null>(null);

  const appendToLast = useCallback((delta: string) => {
    setMessages((ms) => {
      const last = ms[ms.length - 1];
      if (!last || last.role !== 'assistant') return ms;
      return [...ms.slice(0, -1), { ...last, content: last.content + delta }];
    });
  }, []);

  const stop = useCallback(() => {
    abortRef.current?.abort();
  }, []);

  const send = useCallback(
    async ({ text, accessCode, canvasMermaid }: SendArgs): Promise<SendResult> => {
      const userMsg: ChatMessage = { role: 'user', content: text };
      const history = [...messages, userMsg];
      setMessages(history);
      setError('');
      setStreaming(true);
      const ctrl = new AbortController();
      abortRef.current = ctrl;

      try {
        const res = await fetch('/api/chat', {
          method: 'POST',
          headers: { 'content-type': 'application/json' },
          signal: ctrl.signal,
          body: JSON.stringify({
            messages: history.map((m) => ({ role: m.role, content: m.content })),
            accessCode,
            ...(canvasMermaid ? { canvasMermaid } : {}),
          }),
        });

        if (!res.ok) {
          // odelivererat → ta tillbaka användarens meddelande så det kan skickas om
          setMessages(messages);
          if (res.status === 401) return 'unauthorized';
          let msg = `fel (${res.status})`;
          try {
            const j = (await res.json()) as { error?: string };
            if (j.error) msg = j.error;
          } catch {
            // icke-JSON-fel
          }
          setError(msg);
          return 'error';
        }

        setMessages([...history, { role: 'assistant', content: '' }]);
        const reader = res.body?.getReader();
        if (!reader) {
          setError('tomt svar från servern');
          return 'error';
        }
        const decoder = new TextDecoder();
        let buffer = '';
        for (;;) {
          const { done, value } = await reader.read();
          if (done) break;
          buffer += decoder.decode(value, { stream: true });
          const lines = buffer.split('\n');
          buffer = lines.pop() ?? '';
          for (const line of lines) {
            if (!line.startsWith('data:')) continue;
            const { text: delta, error: evError } = parseSSEData(line.slice(5).trim());
            if (delta) appendToLast(delta);
            if (evError) {
              setError(evError);
              return 'error';
            }
          }
        }
        return 'ok';
      } catch (e) {
        if ((e as Error).name === 'AbortError') return 'ok'; // stoppad — behåll det som hunnit komma
        setError('nätverksfel — försök igen');
        return 'error';
      } finally {
        setStreaming(false);
        abortRef.current = null;
      }
    },
    [messages, appendToLast],
  );

  return { messages, streaming, error, send, stop };
}
