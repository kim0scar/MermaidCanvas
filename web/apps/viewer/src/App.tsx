import { type DragEvent, Suspense, lazy, useCallback, useEffect, useRef, useState } from 'react';
import {
  extractMermaid,
  parseCanvasFile,
  parseNativeState,
  rebindNativeState,
  isLegacyState,
  generateNativeState,
  generateMermaidBody,
  composeNewCanvasFile,
  replaceCanvasPayload,
  newFileExtras,
  type NativeState,
} from '@v2e/domain';
import { loadDocIntoEditor, readDocFromEditor } from '@v2e/canvas';
import type { Editor } from 'tldraw';
import { renderMermaid } from './mermaid-render';
import { encodeShareLink, decodeShareFromHash } from './share-link';

// Rit-ytan (tldraw, ~2 MB) lazy-laddas — visnings-/delningsläget ska vara blixtsnabbt.
const CanvasEditor = lazy(() =>
  import('./canvas/CanvasEditor').then((m) => ({ default: m.CanvasEditor })),
);

type Mode = 'rita' | 'visa';

function downloadText(name: string, text: string): void {
  const blob = new Blob([text], { type: 'text/markdown' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = name;
  a.click();
  URL.revokeObjectURL(a.href);
}

export function App() {
  const [source, setSource] = useState('');
  const [svg, setSvg] = useState('');
  const [error, setError] = useState('');
  const [isCanvasFile, setIsCanvasFile] = useState(false);
  const [legacy, setLegacy] = useState(false);
  const [copied, setCopied] = useState(false);
  const [mode, setMode] = useState<Mode>('visa');
  const [fileName, setFileName] = useState('canvas.md');
  const [warnings, setWarnings] = useState<string[]>([]);
  const [savedFlash, setSavedFlash] = useState(false);
  const [docKey, setDocKey] = useState(0);
  const nativeRef = useRef<NativeState | null>(null);
  const editorRef = useRef<Editor | null>(null);
  const [canDraw, setCanDraw] = useState(false);

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

  /** Öppna text som canvas om möjligt (modernt state-block) — annars bara visning. */
  const openText = useCallback(
    (text: string, opts?: { stayInVisa?: boolean }) => {
      setSource(text);
      setWarnings([]);
      void render(text);
      const parsed = parseCanvasFile(text);
      if (parsed.stateJson && !isLegacyState(parsed.stateJson)) {
        try {
          nativeRef.current = parseNativeState(parsed.stateJson);
          setLegacy(false);
          setCanDraw(true);
          setDocKey((k) => k + 1);
          if (!opts?.stayInVisa) setMode('rita');
          return;
        } catch {
          // trasig state-JSON → behandla som legacy (visas, redigeras ej)
        }
      }
      nativeRef.current = null;
      setCanDraw(false);
      setLegacy(parsed.hasStateBlock);
      setMode('visa');
    },
    [render],
  );

  // Vid start: finns en delad länk (#d=...) → ladda och rita den.
  useEffect(() => {
    const shared = decodeShareFromHash(window.location.hash);
    if (shared) openText(shared, { stayInVisa: true });
  }, [openText]);

  const onFile = (file: File) => {
    setFileName(file.name.endsWith('.md') ? file.name : `${file.name}.md`);
    const reader = new FileReader();
    reader.onload = () => openText(String(reader.result ?? ''));
    reader.readAsText(file);
  };

  const onDrop = (e: DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    const file = e.dataTransfer.files.item(0);
    if (file) onFile(file);
  };

  const onNewCanvas = () => {
    nativeRef.current = {
      doc: { shapes: [], edges: [] },
      extras: newFileExtras(),
      rawNodes: new Map(),
      rawEdges: new Map(),
    };
    setSource('');
    setFileName('ny-canvas.md');
    setSvg('');
    setError('');
    setWarnings([]);
    setLegacy(false);
    setIsCanvasFile(true);
    setCanDraw(true);
    setDocKey((k) => k + 1);
    setMode('rita');
  };

  const onEditorMount = useCallback((editor: Editor) => {
    editorRef.current = editor;
    if (nativeRef.current) loadDocIntoEditor(editor, nativeRef.current.doc);
  }, []);

  const onSave = () => {
    const editor = editorRef.current;
    const native = nativeRef.current;
    if (!editor || !native) return;
    const { doc, warnings: w } = readDocFromEditor(editor);
    setWarnings(w);
    const stateJson = generateNativeState(doc, native);
    const body = generateMermaidBody(doc);
    const text = source.trim()
      ? replaceCanvasPayload(source, body, stateJson)
      : composeNewCanvasFile({
          title: fileName.replace(/\.md$/i, ''),
          mermaidBody: body,
          stateJson,
          isoTimestamp: new Date().toISOString(),
        });
    downloadText(fileName, text);
    // nästa sparning utgår från det nyss sparade (kirurgisk redigering + rå-bevarande)
    setSource(text);
    nativeRef.current = rebindNativeState(doc, stateJson);
    setIsCanvasFile(true);
    void render(text);
    setSavedFlash(true);
    window.setTimeout(() => setSavedFlash(false), 2000);
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
        <p>Rita, öppna eller klistra in en canvas.</p>
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
        <button className="btn" onClick={onNewCanvas}>✨ Ny canvas</button>
        {canDraw && (
          <div className="tabs" role="tablist">
            <button
              className={mode === 'rita' ? 'tab active' : 'tab'}
              onClick={() => setMode('rita')}
            >
              🎨 Rita
            </button>
            <button
              className={mode === 'visa' ? 'tab active' : 'tab'}
              onClick={() => setMode('visa')}
            >
              👁 Visa
            </button>
          </div>
        )}
        {canDraw && mode === 'rita' && (
          <button className="btn primary" onClick={onSave}>
            {savedFlash ? '✓ Sparad' : '💾 Spara .md'}
          </button>
        )}
        <button className="btn" onClick={() => void onShare()} disabled={!source.trim()}>
          {copied ? '✓ Länk kopierad' : '🔗 Dela'}
        </button>
        {isCanvasFile && !legacy && <span className="badge">MermaidCanvas-fil</span>}
        {legacy && (
          <span className="badge warn">
            Äldre app-fil — visas som bild (spara om den i appen för att rita här)
          </span>
        )}
      </div>

      {warnings.length > 0 && (
        <div className="warnings">
          {warnings.map((w, i) => (
            <div key={i}>⚠️ {w}</div>
          ))}
        </div>
      )}

      {canDraw && mode === 'rita' ? (
        <Suspense fallback={<div className="hint" style={{ padding: 24 }}>Laddar rit-ytan…</div>}>
          <CanvasEditor key={docKey} onMount={onEditorMount} />
        </Suspense>
      ) : (
        <main className="stage">
          {svg ? (
            <div className="diagram" dangerouslySetInnerHTML={{ __html: svg }} />
          ) : error ? null : (
            <div className="hint">
              Tryck <b>✨ Ny canvas</b> och rita direkt — eller släpp en <b>.md</b>-fil här,
              tryck <b>Öppna fil</b>, eller klistra in mermaid nedan.
            </div>
          )}
          {error && (
            <div className="error">
              <b>Kunde inte rita diagrammet</b>
              <pre>{error}</pre>
            </div>
          )}
        </main>
      )}

      {mode !== 'rita' && (
        <details className="paste">
          <summary>Klistra in text</summary>
          <textarea
            value={source}
            onChange={(e) => openText(e.target.value, { stayInVisa: false })}
            placeholder="Klistra in .md-innehåll eller ren mermaid…"
            spellCheck={false}
          />
        </details>
      )}
    </div>
  );
}
