// W2-grinden: det RIKTIGA state-schemat läses/skrivs förlustfritt.
// Fixturer = riktiga app-sparade filer ur Kims iCloud (modern v49 + legacy).
import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import {
  generateNativeState,
  isLegacyState,
  makeEdge,
  makeShape,
  parseCanvasFile,
  parseNativeState,
  rebindNativeState,
  composeNewCanvasFile,
  replaceCanvasPayload,
} from '../src/index.js';

const modernPath = fileURLToPath(new URL('./fixtures/native-v49-modern.md', import.meta.url));
const legacyPath = fileURLToPath(new URL('./fixtures/native-alla-former.md', import.meta.url));
const modernMd = readFileSync(modernPath, 'utf8');
const legacyMd = readFileSync(legacyPath, 'utf8');
const modernState = parseCanvasFile(modernMd).stateJson!;
const legacyState = parseCanvasFile(legacyMd).stateJson!;

describe('isLegacyState', () => {
  it('modern v49-fil är INTE legacy', () => {
    expect(isLegacyState(modernState)).toBe(false);
  });
  it('gammal fil (bidirectional-kanter + utdöd typ) ÄR legacy', () => {
    expect(isLegacyState(legacyState)).toBe(true);
  });
});

describe('parseNativeState — riktig modern fil', () => {
  const state = parseNativeState(modernState);

  it('läser alla noder + kanter', () => {
    expect(state.doc.shapes).toHaveLength(129);
    expect(state.doc.edges).toHaveLength(128);
  });

  it('nod-fält mappas (id = mermaid-id, platta x/y → position, size → sizeMultiplier)', () => {
    const first = state.doc.shapes[0]!;
    expect(first.id).toMatch(/_N0$/);
    expect(typeof first.position.x).toBe('number');
    expect(first.sizeMultiplier).toBeGreaterThan(0);
    expect(first.showLabel).toBeDefined();
  });

  it('kanter refererar existerande noder', () => {
    const ids = new Set(state.doc.shapes.map((s) => s.id));
    for (const e of state.doc.edges) {
      expect(ids.has(e.from)).toBe(true);
      expect(ids.has(e.to)).toBe(true);
    }
  });
});

describe('round-trip: parse → generate → parse = samma modell', () => {
  it('modern fil round-trippar förlustfritt (djup-lika dokument + idempotent text)', () => {
    const s1 = parseNativeState(modernState);
    const out1 = generateNativeState(s1.doc, s1);
    const s2 = parseNativeState(out1);
    expect(s2.doc).toEqual(s1.doc);
    const out2 = generateNativeState(s2.doc, s2);
    expect(out2).toBe(out1);
  });

  it('okända rå-fält (framtida/omodellerade nycklar) överlever oförändrade', () => {
    const root = JSON.parse(modernState);
    root.nodes[0].framtidsFalt = { djup: [1, 2, 3] };
    root.edges[0].collapsed = true;
    root.experimentToppNyckel = 'bevaras';
    const s = parseNativeState(JSON.stringify(root));
    const out = generateNativeState(s.doc, s);
    const reparsed = JSON.parse(out);
    expect(reparsed.nodes[0].framtidsFalt).toEqual({ djup: [1, 2, 3] });
    expect(reparsed.edges[0].collapsed).toBe(true);
    expect(reparsed.experimentToppNyckel).toBe('bevaras');
  });

  it('rebindNativeState: okända rå-fält överlever ÄVEN en andra sparning', () => {
    const root = JSON.parse(modernState);
    root.nodes[7].hemligtFalt = 'ska överleva två sparningar';
    const s1 = parseNativeState(JSON.stringify(root));

    const save1 = generateNativeState(s1.doc, s1);
    const s2 = rebindNativeState(s1.doc, save1);
    s2.doc.shapes[0]!.position = { x: 1, y: 2 }; // ändra något mellan sparningarna
    const save2 = generateNativeState(s2.doc, s2);

    expect(JSON.parse(save2).nodes[7].hemligtFalt).toBe('ska överleva två sparningar');
  });

  it('en flyttad form uppdaterar x/y men rör inget annat', () => {
    const s = parseNativeState(modernState);
    const moved = s.doc.shapes[3]!;
    moved.position = { x: 4321.5, y: 1234.25 };
    const out = generateNativeState(s.doc, s);
    const reparsed = JSON.parse(out);
    expect(reparsed.nodes[3].x).toBe(4321.5);
    expect(reparsed.nodes[3].y).toBe(1234.25);
    expect(reparsed.nodes[3].label).toBe(s.doc.shapes[3]!.label);
    expect(reparsed.nodes).toHaveLength(129);
  });
});

describe('ny fil skapad i webben', () => {
  const doc = {
    shapes: [
      makeShape({ id: 'ui_N0', type: 'circle', position: { x: 100, y: 100 }, label: 'Start' }),
      makeShape({ id: 'ui_N1', type: 'diamond', position: { x: 300, y: 100 }, label: 'Beslut?' }),
    ],
    edges: [makeEdge({ id: 'e0', from: 'ui_N0', to: 'ui_N1', label: 'sen' })],
  };

  it('generateNativeState utan rå-underlag ger läsbart nuvarande schema', () => {
    const out = generateNativeState(doc);
    const s = parseNativeState(out);
    expect(s.doc.shapes.map((x) => x.type)).toEqual(['circle', 'diamond']);
    expect(s.doc.edges[0]!.label).toBe('sen');
    expect(s.extras.specType).toBe('general');
    const raw = JSON.parse(out);
    expect(raw.nodes[0].id).toBe('ui_N0');
    expect(raw.edges[0].direction).toBe('forward');
    // villkorliga fält skrivs INTE när de är default (som Swift)
    expect('bold' in raw.nodes[0]).toBe(false);
    expect('textStyle' in raw.nodes[0]).toBe(false);
  });

  it('composeNewCanvasFile ger en fil som visaren + parsern läser', () => {
    const state = generateNativeState(doc);
    const md = composeNewCanvasFile({
      title: 'Webbtest',
      mermaidBody: 'flowchart TD\n    ui_N0(("Start"))',
      stateJson: state,
      isoTimestamp: '2026-07-02T12:00:00Z',
    });
    const parsed = parseCanvasFile(md);
    expect(parsed.hasStateBlock).toBe(true);
    expect(parsed.mermaid.startsWith('flowchart TD')).toBe(true);
    expect(parseNativeState(parsed.stateJson!).doc.shapes).toHaveLength(2);
    expect(md).toContain('last_updated: 2026-07-02');
  });
});

describe('replaceCanvasPayload — kirurgisk uppdatering', () => {
  it('allt utanför fence + state-block bevaras byte-exakt', () => {
    const s = parseNativeState(modernState);
    const newState = generateNativeState(s.doc, s);
    const updated = replaceCanvasPayload(modernMd, 'flowchart TD\n    ui_N0["A"]', newState);

    // frontmatter + brödtext före fencen orörda
    const beforeFenceOrig = modernMd.slice(0, modernMd.indexOf('```mermaid'));
    const beforeFenceNew = updated.slice(0, updated.indexOf('```mermaid'));
    expect(beforeFenceNew).toBe(beforeFenceOrig);

    // allt efter state-blockets slut orört (OBS: '-->' finns även som mermaid-pil i kroppen —
    // leta stängningen EFTER state-markören)
    const closeAfter = (text: string) => text.indexOf('-->', text.indexOf('<!-- mermaidcanvas-state')) + 3;
    const tailOrig = modernMd.slice(closeAfter(modernMd));
    const tailNew = updated.slice(closeAfter(updated));
    expect(tailNew).toBe(tailOrig);

    // nya innehållet är på plats och läsbart
    const parsed = parseCanvasFile(updated);
    expect(parsed.mermaid).toBe('flowchart TD\n    ui_N0["A"]');
    expect(parseNativeState(parsed.stateJson!).doc.shapes).toHaveLength(129);
  });
});
