import { describe, it, expect } from 'vitest';
import {
  makeShape, makeEdge, generateStateBlock, parseStateBlock, generateMermaidBody,
  type CanvasDoc,
} from '../src/index.js';

// FAS 0 — den BLOCKERANDE noll-avvikelse-grinden (Tier 1, state-JSON): modell → serialisera →
// parsa → EXAKT samma modell. Detta är den körbara specen för Kims noll-avvikelse-garanti,
// portad från Swift RoundTripFidelityTests / StateJSONSymmetryTests. Får aldrig mjukas upp.

function sampleDoc(): CanvasDoc {
  const a = makeShape({ id: 'A', type: 'circle', position: { x: 50, y: 50 }, label: 'Cirkel', category: 'ui' });
  const b = makeShape({
    id: 'B', type: 'rectangle', position: { x: 200, y: 50 }, label: 'Rektangel',
    category: 'ui', bold: true, hasBullets: true, indentLevel: 1, textAlignment: 'leading',
  });
  const c = makeShape({
    id: 'C', type: 'diamond', position: { x: 350, y: 50 }, label: 'Beslut?', category: 'router',
    colorOverride: '#ffcc00', rotation: 15, widthMultiplier: 1.5, heightMultiplier: 0.75,
  });
  const e1 = makeEdge({ id: 'e0', from: 'A', to: 'C', label: 'ja', lineShape: 'straight' });
  const e2 = makeEdge({ id: 'e1', from: 'C', to: 'B', direction: 'bidirectional', style: 'dashed' });
  return { shapes: [a, b, c], edges: [e1, e2] };
}

describe('Tier 1 state-JSON round-trip (noll-avvikelse)', () => {
  it('modell → state-block → modell ger EXAKT samma modell', () => {
    const doc = sampleDoc();
    const block = generateStateBlock(doc);
    const back = parseStateBlock(block);
    expect(back).toEqual(doc);
  });

  it('överlever att state-blocket ligger inbäddat i en större markdown-fil', () => {
    const doc = sampleDoc();
    const file = `# min fil\n\n${generateMermaidBody(doc)}\n${generateStateBlock(doc)}\n\nslut.`;
    const back = parseStateBlock(file);
    expect(back).toEqual(doc);
  });

  it('kastar tydligt när state-blocket saknas', () => {
    expect(() => parseStateBlock('bara text, inget block')).toThrow(/state-JSON-block saknas/);
  });
});

describe('Tier 2 mermaid-kropp (delmängd) — renderbar struktur', () => {
  it('har header + en nod-rad + pos/name-bärare per form', () => {
    const body = generateMermaidBody(sampleDoc());
    expect(body).toContain('flowchart TD');
    expect(body).toContain('((\"Cirkel\"))'); // cirkel-omslag
    expect(body).toContain('{\"Beslut?\"}'); // diamant-omslag
    expect(body).toMatch(/%% \w+ pos: 50,50/);
    expect(body).toContain('classDef ui');
    expect(body).toContain('classDef router');
  });
});
