// State-JSON — det FÖRLUSTFRIA lagret (Tier 1). Motsvarar Swift MermaidGenerator+StateJSON.swift.
// Detta bär appens fullständiga modell byte-exakt (noll-avvikelse). Ren mermaid-kroppen (Tier 2)
// är transporten som en läsare/AI ser; state-blocket är den exakta återställningen.
//
// Markör: `<!-- mermaidcanvas-state ... -->`. OBS: exakt byte-layout (radbrytning/indrag/nyckel-
// ordning) måste sam-verifieras mot Swift-emissionen när Swift↔TS golden-diff-grinden byggs
// (Fas 0, nästa steg). TS↔TS round-trip nedan är den första grinden och är redan blockerande.

import type { CanvasDoc } from './model.js';

const OPEN = '<!-- mermaidcanvas-state';
const CLOSE = '-->';

/** Serialisera dokumentet till state-JSON-blocket (Tier 1, förlustfritt). */
export function generateStateBlock(doc: CanvasDoc): string {
  const json = JSON.stringify(doc, null, 2);
  return `${OPEN}\n${json}\n${CLOSE}`;
}

/** Läs tillbaka dokumentet ur state-JSON-blocket. Kastar om blocket saknas/är trasigt. */
export function parseStateBlock(text: string): CanvasDoc {
  const start = text.indexOf(OPEN);
  if (start === -1) throw new Error('state-JSON-block saknas (ingen mermaidcanvas-state-markör)');
  const afterOpen = start + OPEN.length;
  const end = text.indexOf(CLOSE, afterOpen);
  if (end === -1) throw new Error('state-JSON-block ej stängt (ingen -->-markör)');
  const jsonText = text.slice(afterOpen, end).trim();
  const parsed = JSON.parse(jsonText) as CanvasDoc;
  if (!Array.isArray(parsed.shapes) || !Array.isArray(parsed.edges)) {
    throw new Error('state-JSON: förväntade { shapes: [], edges: [] }');
  }
  return parsed;
}
