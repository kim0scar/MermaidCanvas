// Fristående chatpanel — ägaren av App.tsx kopplar in den via props-kontraktet.

import { type KeyboardEvent, useEffect, useRef, useState } from 'react';
import { splitMermaidBlocks } from './mermaid-blocks';
import { useChatStream } from './useChatStream';
import './copilot.css';

const CODE_KEY = 'v2e-access-code';

export interface ChatPanelProps {
  getCanvasMermaid: () => string;
  onApplyMermaid: (mermaid: string) => { ok: boolean; error?: string };
}

export function ChatPanel({ getCanvasMermaid, onApplyMermaid }: ChatPanelProps) {
  const [accessCode, setAccessCode] = useState(() => localStorage.getItem(CODE_KEY) ?? '');
  const [needsCode, setNeedsCode] = useState(accessCode === '');
  const [rejected, setRejected] = useState(false);
  const [codeInput, setCodeInput] = useState('');
  const [input, setInput] = useState('');
  const [applyState, setApplyState] = useState<Record<string, string>>({});
  const { messages, streaming, error, send, stop } = useChatStream();
  const listRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    listRef.current?.scrollTo({ top: listRef.current.scrollHeight });
  }, [messages]);

  const saveCode = () => {
    const code = codeInput.trim();
    if (!code) return;
    localStorage.setItem(CODE_KEY, code);
    setAccessCode(code);
    setCodeInput('');
    setNeedsCode(false);
    setRejected(false);
  };

  const onSend = async () => {
    const text = input.trim();
    if (!text || streaming || needsCode) return;
    setInput('');
    const canvas = getCanvasMermaid();
    const result = await send({
      text,
      accessCode,
      ...(canvas.trim() ? { canvasMermaid: canvas } : {}),
    });
    if (result === 'unauthorized') {
      localStorage.removeItem(CODE_KEY);
      setAccessCode('');
      setNeedsCode(true);
      setRejected(true);
      setInput(text); // inget skickades — låt texten ligga kvar
    }
  };

  const onKey = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      void onSend();
    }
  };

  const onApply = (key: string, code: string) => {
    const r = onApplyMermaid(code);
    setApplyState((s) => ({ ...s, [key]: r.ok ? 'ok' : (r.error ?? 'Kunde inte användas i canvasen.') }));
  };

  return (
    <div className="copilot">
      {needsCode && (
        <div className="copilot-gate">
          <label htmlFor="v2e-code">Åtkomstkod</label>
          <div className="copilot-gate-row">
            <input
              id="v2e-code"
              type="password"
              value={codeInput}
              placeholder="Skriv din kod"
              onChange={(e) => setCodeInput(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && saveCode()}
            />
            <button className="copilot-btn primary" onClick={saveCode} disabled={!codeInput.trim()}>
              Lås upp
            </button>
          </div>
          {rejected && <p className="copilot-hint">Fel åtkomstkod — prova igen.</p>}
        </div>
      )}

      <div className="copilot-msgs" ref={listRef}>
        {messages.length === 0 && (
          <p className="copilot-hint">Beskriv flödet du vill rita, så föreslår AI:n ett diagram.</p>
        )}
        {messages.map((m, i) =>
          m.role === 'user' ? (
            <div key={i} className="copilot-msg user">
              {m.content}
            </div>
          ) : (
            <div key={i} className="copilot-msg ai">
              {splitMermaidBlocks(m.content).map((seg, j) => {
                if (seg.kind === 'text') return <p key={j}>{seg.content}</p>;
                const key = `${i}:${j}`;
                const state = applyState[key];
                return (
                  <div key={j} className="copilot-code">
                    <pre>
                      <code>{seg.content}</code>
                    </pre>
                    <button className="copilot-btn" onClick={() => onApply(key, seg.content)} disabled={streaming}>
                      {state === 'ok' ? '✓ Inlagd' : '🎨 Använd i canvasen'}
                    </button>
                    {state && state !== 'ok' && <p className="copilot-apply-error">{state}</p>}
                  </div>
                );
              })}
              {streaming && i === messages.length - 1 && <span className="copilot-cursor" />}
            </div>
          ),
        )}
        {error && <p className="copilot-error">{error}</p>}
      </div>

      <div className="copilot-input">
        <textarea
          value={input}
          rows={1}
          placeholder="Vad vill du rita?"
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={onKey}
        />
        {streaming ? (
          <button className="copilot-btn" onClick={stop}>
            ⏹ Stoppa
          </button>
        ) : (
          <button className="copilot-btn primary" onClick={() => void onSend()} disabled={!input.trim() || needsCode}>
            Skicka
          </button>
        )}
      </div>
    </div>
  );
}
