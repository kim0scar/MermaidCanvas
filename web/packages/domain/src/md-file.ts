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

// ---- Skrivsidan (Fas 2) — kirurgisk fil-uppdatering + ny fil ----

function stateBlock(stateJson: string): string {
  return `${STATE_OPEN}\n${stateJson}\n${STATE_CLOSE}`;
}

/**
 * Kirurgiskt byte av fence-kropp + state-block i en BEFINTLIG fil.
 * Allt annat (frontmatter, brödtext, inbäddat AI-ramverk, okända sektioner) bevaras byte-exakt —
 * det är noll-avvikelse-vägen: vi redigerar bara det canvasen äger.
 */
export function replaceCanvasPayload(originalText: string, mermaidBody: string, stateJson: string): string {
  const newFence = '```mermaid\n' + mermaidBody.trimEnd() + '\n```';
  let text = MERMAID_FENCE.test(originalText)
    ? originalText.replace(MERMAID_FENCE, () => newFence)
    : originalText.trimEnd() + '\n\n' + newFence + '\n';

  const start = text.indexOf(STATE_OPEN);
  if (start !== -1) {
    const end = text.indexOf(STATE_CLOSE, start + STATE_OPEN.length);
    if (end !== -1) {
      return text.slice(0, start) + stateBlock(stateJson) + text.slice(end + STATE_CLOSE.length);
    }
  }
  // Inget state-block fanns → lägg det direkt efter fencen (samma plats som appen skriver det).
  const fenceEnd = text.indexOf(newFence) + newFence.length;
  return text.slice(0, fenceEnd) + '\n\n' + stateBlock(stateJson) + text.slice(fenceEnd);
}

/**
 * Komponera en NY canvas-fil — samma layout som Swift CanvasDocument (frontmatter + rubrik +
 * "Genererad …" + fence + state-block). `isoTimestamp` skickas in (ren funktion, deterministisk).
 * OBS: det inbäddade AI-ramverket (AppCapabilities.embeddedFrameworkBlock) portas i W3
 * (capabilities.ts) — tills dess får NYA webb-filer inget ramverks-block (befintliga filers
 * block bevaras alltid av replaceCanvasPayload).
 */
export function composeNewCanvasFile(opts: {
  title: string;
  mermaidBody: string;
  stateJson: string;
  isoTimestamp: string;
}): string {
  const title = (opts.title.trim() || 'Canvas — MermaidCanvas').replace(/\n/g, ' ');
  const today = opts.isoTimestamp.slice(0, 10);
  return (
    `---\n` +
    `title: ${title}\n` +
    `spec_type: general\n` +
    `platform: blank\n` +
    `shape_packs: basic\n` +
    `last_updated: ${today}\n` +
    `---\n\n` +
    `# ${title}\n\n` +
    `Genererad ${opts.isoTimestamp}.\n\n` +
    '```mermaid\n' + opts.mermaidBody.trimEnd() + '\n```\n\n' +
    stateBlock(opts.stateJson) + '\n'
  );
}
