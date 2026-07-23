import { type DragEvent, Suspense, lazy, useCallback, useEffect, useRef, useState } from 'react';
import {
  extractMermaid,
  parseCanvasFile,
  parseMermaidBody,
  parseNativeState,
  rebindNativeState,
  isLegacyState,
  generateNativeState,
  generateMermaidBody,
  composeNewCanvasFile,
  replaceCanvasPayload,
  newFileExtras,
  frameworkText,
  type NativeState,
} from '@v2e/domain';
import {
  loadDocIntoEditor,
  readDocFromEditor,
  addDomainShape,
  applyColorPack,
  applyCustomColor,
  applyTextStyle,
  PICKER_PACKS,
} from '@v2e/canvas';
import type { Editor } from 'tldraw';
import type { CanvasDoc, ShapeType } from '@v2e/domain';
import { renderMermaid } from './mermaid-render';
import { encodeShareLink, decodeShareFromHash } from './share-link';
import { TopBar, type SubRow } from './ui/TopBar';
import { ShapesRow } from './ui/ShapesRow';
import { ColorsRow } from './ui/ColorsRow';
import { TextStyleRow, type TextStylePatch } from './ui/TextStyleRow';
import { LagenMenu } from './ui/LagenMenu';
import { CodeSheet } from './ui/CodeSheet';
import { EMPTY_SELECTION, type SelectionState } from './canvas/selection';
import { ChatPanel } from './copilot/ChatPanel';
import { WEB_VERSION } from './version';
import './ui/ios.css';

// Rit-ytan (tldraw, ~2 MB) lazy-laddas — start/visnings-läget ska vara blixtsnabbt.
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

const PACK_CHIPS = PICKER_PACKS.map((p, i) => ({
  id: i,
  name: p.name,
  fill: p.fill,
  stroke: p.stroke,
  text: p.text,
}));

/** Canvas-mått ur NativeState (matchar state-blockets canvas-dict) → %% canvas-size-bäraren. */
function canvasSizeOf(native: NativeState): { width: number; height: number } | undefined {
  const c = (native.extras as Record<string, unknown>).canvas as
    | { width?: unknown; height?: unknown }
    | undefined;
  return typeof c?.width === 'number' && typeof c?.height === 'number'
    ? { width: c.width, height: c.height }
    : undefined;
}

export function App() {
  const [source, setSource] = useState('');
  const [svg, setSvg] = useState('');
  const [error, setError] = useState('');
  const [legacy, setLegacy] = useState(false);
  const [mode, setMode] = useState<Mode>('visa');
  const [fileName, setFileName] = useState('canvas.md');
  const [warnings, setWarnings] = useState<string[]>([]);
  const [notice, setNotice] = useState('');
  const [savedFlash, setSavedFlash] = useState(false);
  const [docKey, setDocKey] = useState(0);
  const [canDraw, setCanDraw] = useState(false);
  const [subRow, setSubRow] = useState<SubRow>(null);
  const [aiOpen, setAiOpen] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const [codeText, setCodeText] = useState<string | null>(null);
  const [sel, setSel] = useState<SelectionState>(EMPTY_SELECTION);
  const [zoomPct, setZoomPct] = useState<number | null>(null);
  const [toolId, setToolId] = useState('select');
  const nativeRef = useRef<NativeState | null>(null);
  const editorRef = useRef<Editor | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  const flashNotice = (text: string) => {
    setNotice(text);
    window.setTimeout(() => setNotice(''), 2000);
  };

  const render = useCallback(async (text: string) => {
    const parsed = parseCanvasFile(text);
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

  /** Nuvarande fil-text: i rit-läget genereras den ur editorn, annars källan. */
  const currentText = useCallback((): string => {
    const editor = editorRef.current;
    const native = nativeRef.current;
    if (!editor || !native || !canDraw) return source;
    const { doc } = readDocFromEditor(editor);
    const stateJson = generateNativeState(doc, native);
    const body = generateMermaidBody(doc, { canvasSize: canvasSizeOf(native) });
    return source.trim()
      ? replaceCanvasPayload(source, body, stateJson)
      : composeNewCanvasFile({
          title: fileName.replace(/\.md$/i, ''),
          mermaidBody: body,
          stateJson,
          isoTimestamp: new Date().toISOString(),
          frameworkBlock: frameworkText(),
        });
  }, [canDraw, source, fileName]);

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

  // Vid start: finns en delad länk (#d=...) → ladda och visa den.
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

  const onNewCanvas = useCallback(() => {
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
    setCanDraw(true);
    setDocKey((k) => k + 1);
    setMode('rita');
    setSubRow('shapes');
  }, []);

  // Tryck på form-chips innan rit-motorn laddat klart (lazy, långsamt på mobil)
  // slängdes tyst — köa dem och utför vid mount i stället.
  const pendingShapesRef = useRef<ShapeType[]>([]);
  const onAddShape = useCallback((t: ShapeType) => {
    const ed = editorRef.current;
    if (ed) addDomainShape(ed, t);
    else pendingShapesRef.current.push(t);
  }, []);

  const onEditorMount = useCallback((editor: Editor) => {
    editorRef.current = editor;
    // Test-krok: e2e-testerna läser editor-state via window (skadar inget i drift).
    (window as unknown as Record<string, unknown>).__v2eEditor = editor;
    if (nativeRef.current) loadDocIntoEditor(editor, nativeRef.current.doc);
    // Flush i nästa tick och bara om detta fortfarande är den aktiva editorn —
    // StrictMode (dev) monterar två gånger och slänger den första instansen.
    setTimeout(() => {
      if (editorRef.current !== editor) return;
      const pending = pendingShapesRef.current.splice(0);
      for (const t of pending) addDomainShape(editor, t);
    }, 0);
  }, []);

  const onSave = () => {
    const editor = editorRef.current;
    const native = nativeRef.current;
    if (!editor || !native) return;
    const { doc, warnings: w } = readDocFromEditor(editor);
    setWarnings(w);
    const stateJson = generateNativeState(doc, native);
    const body = generateMermaidBody(doc, { canvasSize: canvasSizeOf(native) });
    const text = source.trim()
      ? replaceCanvasPayload(source, body, stateJson)
      : composeNewCanvasFile({
          title: fileName.replace(/\.md$/i, ''),
          mermaidBody: body,
          stateJson,
          isoTimestamp: new Date().toISOString(),
          frameworkBlock: frameworkText(),
        });
    downloadText(fileName, text);
    // nästa sparning utgår från det nyss sparade (kirurgisk redigering + rå-bevarande)
    setSource(text);
    nativeRef.current = rebindNativeState(doc, stateJson);
    void render(text);
    setSavedFlash(true);
    window.setTimeout(() => setSavedFlash(false), 2000);
  };

  const onShare = async () => {
    const base = window.location.origin + window.location.pathname;
    const link = encodeShareLink(base, extractMermaid(currentText()));
    try {
      await navigator.clipboard.writeText(link);
      flashNotice('✓ Länk kopierad');
    } catch {
      // Urklipp kan nekas (t.ex. utan HTTPS) → lägg länken i adressraden istället.
      window.location.hash = new URL(link).hash;
    }
  };

  /** AI-förslag: parsas till domän-doc och ritas på canvasen — samma grindar som import. */
  const onApplyMermaid = useCallback(
    (mermaid: string): { ok: boolean; error?: string } => {
      try {
        const { doc } = parseMermaidBody(mermaid);
        nativeRef.current = {
          doc,
          extras: nativeRef.current?.extras ?? newFileExtras(),
          rawNodes: new Map(),
          rawEdges: new Map(),
        };
        setCanDraw(true);
        setLegacy(false);
        setDocKey((k) => k + 1);
        setMode('rita');
        return { ok: true };
      } catch (e) {
        return { ok: false, error: `Förslaget gick inte att tolka: ${(e as Error).message}` };
      }
    },
    [],
  );

  const rita = canDraw && mode === 'rita';
  const editor = editorRef.current;

  const onToggleRow = (row: Exclude<SubRow, null>) => {
    if (!canDraw) {
      onNewCanvas();
      setSubRow(row);
      return;
    }
    if (mode !== 'rita') setMode('rita');
    setSubRow((r) => (r === row ? null : row));
  };

  const onToggleArrow = () => {
    const ed = editorRef.current;
    if (!ed) return;
    ed.setCurrentTool(toolId === 'arrow' ? 'select' : 'arrow');
  };

  const onToggleView = () => {
    if (mode === 'rita') {
      void render(currentText());
      setMode('visa');
    } else {
      setMode('rita');
    }
  };

  return (
    <div className="app" onDrop={onDrop} onDragOver={(e) => e.preventDefault()}>
      <input
        ref={fileInputRef}
        type="file"
        accept=".md,.mmd,.txt,text/markdown,text/plain"
        hidden
        onChange={(e) => {
          const f = e.target.files?.item(0);
          if (f) onFile(f);
          e.target.value = '';
        }}
      />

      <TopBar
        subRow={rita ? subRow : null}
        onToggleRow={onToggleRow}
        aiOpen={aiOpen}
        onToggleAi={() => setAiOpen((v) => !v)}
        onUndo={rita && editor ? () => editor.undo() : null}
        onRedo={rita && editor ? () => editor.redo() : null}
        onDelete={null}
        zoomPercent={rita ? zoomPct : null}
        onSave={canDraw ? onSave : null}
        saveLabel={savedFlash ? '✓ Sparad' : '💾 Spara'}
        menu={
          <LagenMenu
            a={{
              onNew: onNewCanvas,
              onOpen: () => fileInputRef.current?.click(),
              onSave: canDraw ? onSave : null,
              onShowCode: source.trim() || canDraw ? () => setCodeText(currentText()) : null,
              onCopyCode:
                source.trim() || canDraw
                  ? () => {
                      void navigator.clipboard
                        .writeText(currentText())
                        .then(() => flashNotice('✓ Kod kopierad'));
                    }
                  : null,
              onShare: source.trim() || canDraw ? () => void onShare() : null,
              onToggleView: canDraw ? onToggleView : null,
              viewLabel: mode === 'rita' ? 'Visa diagrammet (mermaid)' : 'Tillbaka till rit-läget',
              onResetZoom: rita && editor ? () => editor.zoomToFit() : null,
              version: WEB_VERSION,
            }}
            onClose={() => setMenuOpen(false)}
          />
        }
        menuOpen={menuOpen}
        onToggleMenu={() => setMenuOpen((v) => !v)}
      />

      {rita && subRow === 'shapes' && (
        <ShapesRow
          onAdd={onAddShape}
          arrowActive={toolId === 'arrow'}
          onToggleArrow={onToggleArrow}
        />
      )}
      {rita && subRow === 'colors' && (
        <ColorsRow
          packs={PACK_CHIPS}
          onPick={(i) => editorRef.current && applyColorPack(editorRef.current, i)}
          fill={sel.color}
          stroke={sel.strokeColor}
          onCustomColor={(p) => editorRef.current && applyCustomColor(editorRef.current, p)}
        />
      )}
      {rita && subRow === 'text' && (
        <TextStyleRow
          state={sel}
          onApply={(p: TextStylePatch) => editorRef.current && applyTextStyle(editorRef.current, p)}
        />
      )}

      {(warnings.length > 0 || notice || legacy) && (
        <div className="statusline">
          {notice && <span className="badge">{notice}</span>}
          {legacy && (
            <span className="badge warn">
              Äldre app-fil — visas som bild (spara om den i appen för att rita här)
            </span>
          )}
          {warnings.map((w, i) => (
            <span key={i} className="badge warn">
              ⚠️ {w}
            </span>
          ))}
        </div>
      )}

      <div className="canvas-stage">
        {rita ? (
          <Suspense fallback={<div className="hint" style={{ padding: 24 }}>Laddar rit-ytan…</div>}>
            <CanvasEditor
              key={docKey}
              onMount={onEditorMount}
              onSelection={setSel}
              onZoom={setZoomPct}
              onTool={setToolId}
            />
          </Suspense>
        ) : (
          <main className="stage">
            {svg ? (
              <div className="diagram" dangerouslySetInnerHTML={{ __html: svg }} />
            ) : error ? null : (
              <div className="hint">
                <p className="brand">Visuali2e</p>
                <p>
                  Tryck <b>✨ Ny canvas</b> och rita direkt — eller öppna en <b>.md</b>-fil.
                </p>
                <p>
                  <button className="btn primary" onClick={onNewCanvas}>✨ Ny canvas</button>{' '}
                  <button className="btn" onClick={() => fileInputRef.current?.click()}>📂 Öppna fil</button>
                </p>
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

        {rita && sel.count > 0 && editor && (
          <div className="sel-bar">
            <span>{sel.count} markerad{sel.count > 1 ? 'e' : ''}</span>
            <button onClick={() => editor.deleteShapes(editor.getSelectedShapeIds())}>
              🗑 Radera
            </button>
          </div>
        )}

        {aiOpen && (
          <div className="ai-dock">
            <ChatPanel
              getCanvasMermaid={() => extractMermaid(currentText())}
              onApplyMermaid={onApplyMermaid}
            />
          </div>
        )}
      </div>

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

      {codeText !== null && <CodeSheet source={codeText} onClose={() => setCodeText(null)} />}
    </div>
  );
}
