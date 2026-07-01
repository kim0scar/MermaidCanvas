import { type DragEvent, useCallback, useEffect, useState } from 'react';
import { extractMermaid, parseCanvasFile } from '@v2e/domain';
import { renderMermaid } from './mermaid-render';
import { encodeShareLink, decodeShareFromHash } from './share-link';

export function App() {
  const [source, setSource] = useState('');
  const [svg, setSvg] = useState('');
  const [error, setError] = useState('');
  const [isCanvasFile, setIsCanvasFile] = useState(false);
  const [copied, setCopied] = useState(false);

  const render = useCallback(async (text: string) => {
    const parsed = parseCanvasFile(text);
    setIsCanvasFile(parsed.hasStateBlock);
    if (!parsed.mermaid.trim()) {
      setSvg('');
      setError('');
      return;
    }
    const r = await renderMermaid(parsed.mermaid);
    if (r.svg) {
      setSvg(r.svg);
      setError('');
    } else {
      setSvg('');
      setError(r.error ?? 'Kunde inte rita diagrammet.');
    }
  }, []);

  // Vid start: finns en delad länk (#d=...) → ladda och rita den.
  useEffect(() => {
    const shared = decodeShareFromHash(window.location.hash);
    if (shared) {
      setSource(shared);
      void render(shared);
    }
  }, [render]);

  const onText = (text: string) => {
    setSource(text);
    void render(text);
  };

  const onFile = (file: File) => {
    const reader = new FileReader();
    reader.onload = () => onText(String(reader.result ?? ''));
    reader.readAsText(file);
  };

  const onDrop = (e: DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    const file = e.dataTransfer.files.item(0);
    if (file) onFile(file);
  };

  const onShare = async () => {
    const base = window.location.origin + window.location.pathname;
    const link = encodeShareLink(base, extractMermaid(source));
    try {
      await navigator.clipboard.writeText(link);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 2000);
    } catch {
      // Urklipp kan nekas (t.ex. utan HTTPS) → lägg länken i adressraden istället.
      window.location.hash = new URL(link).hash;
    }
  };

  return (
    <div className="app" onDrop={onDrop} onDragOver={(e) => e.preventDefault()}>
      <header>
        <h1>Visuali2e</h1>
        <p>Öppna eller klistra in en canvas — se den direkt.</p>
      </header>

      <div className="bar">
        <label className="btn">
          📂 Öppna fil
          <input
            type="file"
            accept=".md,.mmd,.txt,text/markdown,text/plain"
            hidden
            onChange={(e) => {
              const f = e.target.files?.item(0);
              if (f) onFile(f);
            }}
          />
        </label>
        <button className="btn" onClick={() => void onShare()} disabled={!source.trim()}>
          {copied ? '✓ Länk kopierad' : '🔗 Dela'}
        </button>
        {isCanvasFile && <span className="badge">MermaidCanvas-fil</span>}
      </div>

      <main className="stage">
        {svg ? (
          <div className="diagram" dangerouslySetInnerHTML={{ __html: svg }} />
        ) : error ? null : (
          <div className="hint">
            Släpp en <b>.md</b>-fil här, tryck <b>Öppna fil</b>, eller klistra in mermaid nedan.
          </div>
        )}
        {error && (
          <div className="error">
            <b>Kunde inte rita diagrammet</b>
            <pre>{error}</pre>
          </div>
        )}
      </main>

      <details className="paste">
        <summary>Klistra in text</summary>
        <textarea
          value={source}
          onChange={(e) => onText(e.target.value)}
          placeholder="Klistra in .md-innehåll eller ren mermaid…"
          spellCheck={false}
        />
      </details>
    </div>
  );
}
