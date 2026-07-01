// Läs-visarens fil-parsning (Fas 1) — REN TS, 0 dep. Plockar ut den renderbara mermaid-kroppen ur
// en MermaidCanvas .md-fil så den kan ritas av mermaid.js i webbläsaren. Domänen förblir renderar-fri:
// själva mermaid.js-renderingen bor i app-lagret (viewer), inte här.
//
// OBS: en VISARE måste tåla vilken giltig fil som helst. Den validerar därför INTE state-JSON-schemat —
// formatet har varierat mellan app-versioner (v27-filer har `nodes`/`x,y`, TS-modellen `shapes`/`position`).
// Fas 1 renderar bara mermaid-kroppen; den exakta modell-återställningen (round-trip) hör till Fas 2.

const STATE_OPEN = '<!-- mermaidcanvas-state';
const STATE_CLOSE = '-->';

/** Matchar en ```mermaid ... ``` markdown-fence (första förekomsten). */
const MERMAID_FENCE = /```[ \t]*mermaid[ \t]*\r?\n([\s\S]*?)```/;

/**
 * Plocka ut den renderbara mermaid-kroppen ur .md/.mmd/råtext.
 * - Finns en ```mermaid-fence → returnera dess innehåll (trimmat).
 * - Annars → anta att hela texten redan ÄR mermaid (råklistrad kod) och returnera den trimmad.
 */
export function extractMermaid(text: string): string {
  const m = MERMAID_FENCE.exec(text);
  if (m && m[1] !== undefined) return m[1].trim();
  return text.trim();
}

export interface ParsedCanvasFile {
  /** Renderbar mermaid-kropp (det mermaid.js ritar). */
  mermaid: string;
  /** Finns ett MermaidCanvas state-JSON-block (= filen kommer från appen)? */
  hasStateBlock: boolean;
  /** Rå JSON-text mellan state-markörerna (ej schema-validerad — versioner varierar). */
  stateJson?: string;
}

/** Dela upp en .md-canvasfil i renderbar mermaid + ev. state-block (utan att validera schemat). */
export function parseCanvasFile(text: string): ParsedCanvasFile {
  const mermaid = extractMermaid(text);
  const start = text.indexOf(STATE_OPEN);
  if (start === -1) return { mermaid, hasStateBlock: false };
  const afterOpen = start + STATE_OPEN.length;
  const end = text.indexOf(STATE_CLOSE, afterOpen);
  if (end === -1) return { mermaid, hasStateBlock: true };
  return { mermaid, hasStateBlock: true, stateJson: text.slice(afterOpen, end).trim() };
}
