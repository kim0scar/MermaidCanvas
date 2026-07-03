// Regel 3a-grinden på webbsidan: den mermaid webben GENERERAR måste parsa i RIKTIG mermaid
// (officiella mermaid.parse, samma mekanism som scripts/mermaid-conformance.mjs i native-spåret).
// Körs i vitest med jsdom-miljö (mermaid kräver DOM).
// @vitest-environment jsdom
import { beforeAll, describe, expect, it } from 'vitest';
// ?raw = vite-inbyggd råtext-import (funkar i jsdom-miljön där file-URL:er inte gör det)
import modernMd from './fixtures/native-v49-modern.md?raw';
import {
  generateMermaidBody,
  makeEdge,
  makeShape,
  parseCanvasFile,
  parseNativeState,
  type CanvasDoc,
} from '../src/index.js';

let mermaid: typeof import('mermaid').default;

beforeAll(async () => {
  mermaid = (await import('mermaid')).default;
  mermaid.initialize({ startOnLoad: false, securityLevel: 'loose' });
});

async function expectParses(body: string): Promise<void> {
  const result = await mermaid.parse(body, { suppressErrors: false });
  expect(result).toBeTruthy();
}

describe('webb-genererad mermaid parsar i riktig mermaid', () => {
  it('Kims riktiga v49-dokument (129 former, 128 pilar)', async () => {
    const state = parseCanvasFile(modernMd).stateJson!;
    const doc = parseNativeState(state).doc;
    await expectParses(generateMermaidBody(doc));
  });

  it('alla kant-varianter (riktningar × stilar, med + utan etikett)', async () => {
    const shapes = [
      makeShape({ id: 'a', type: 'circle', position: { x: 0, y: 0 }, label: 'A' }),
      makeShape({ id: 'b', type: 'diamond', position: { x: 200, y: 0 }, label: 'B?' }),
    ];
    const directions = ['forward', 'backward', 'bidirectional', 'none'] as const;
    const styles = ['solid', 'dashed'] as const;
    for (const direction of directions) {
      for (const style of styles) {
        for (const label of ['', 'etikett']) {
          const doc: CanvasDoc = {
            shapes,
            edges: [makeEdge({ id: 'e', from: 'a', to: 'b', direction, style, label })],
          };
          await expectParses(generateMermaidBody(doc));
        }
      }
    }
  });

  it('specialtecken + radbrytning i etiketter', async () => {
    const doc: CanvasDoc = {
      shapes: [
        makeShape({ id: 'a', type: 'rectangle', position: { x: 0, y: 0 }, label: 'Rad 1\nRad 2 "citat"' }),
      ],
      edges: [],
    };
    const body = generateMermaidBody(doc);
    // radbrytningen får inte spräcka %%-raden — namnet ska stå på EN rad,
    // med Swifts oneLine-format (⏎ i stället för radbrytning, omvänds av parsern)
    expect(body).toContain('%% ui_N0 name: Rad 1 ⏎ Rad 2 "citat"');
    await expectParses(body);
  });

  it('alla %%-metadata-nycklar + subgraph + linkStyle förblir parsebara', async () => {
    const container = makeShape({
      id: 'c', type: 'container', position: { x: 500, y: 500 }, label: 'Skill 1',
      category: 'skill', skillNumber: 1, prompt: 'Gör X', note: 'container-obs',
      widthMultiplier: 2, heightMultiplier: 1.5,
    });
    const child = makeShape({
      id: 'k', type: 'table', position: { x: 520, y: 540 }, label: 'Tabell', category: 'ui',
      childOfContainerId: 'c', tableRows: 2, tableCols: 2, tableCells: [['a', 'b'], ['c/d', 'e']],
      locked: true, zLayer: 3, colorPackId: 'blå', textStyle: 'r1', textAlignment: 'leading',
      hasBullets: true, hasNumberedList: true, indentLevel: 2, rotation: 45, sizeMultiplier: 1.4,
      colorOverride: '#ffcc00', strokeColorOverride: '#333333', note: 'nod-obs', prompt: 'p',
      showLabel: false,
    });
    const loose = makeShape({ id: 'l', type: 'arrow', position: { x: 100, y: 100 }, lineEnd: { x: 50, y: 60 } });
    const jump = makeShape({ id: 'j', type: 'link', position: { x: 200, y: 200 }, linkNumber: 7 });
    const edge = makeEdge({
      id: 'e', from: 'k', to: 'j', label: 'går', waypoints: [{ x: 10, y: 20 }],
      labelPlacement: 'above', colorHex: '#ff0000', fromSide: 'right', toSide: 'left',
      lineShape: 'orthogonal',
    });
    const body = generateMermaidBody({ shapes: [container, child, loose, jump], edges: [edge] }, {
      canvasSize: { width: 2000, height: 1000 },
      collapsedEdgeIds: new Set(['e']),
      legend: { ui: 'Egna UI-element' },
    });
    expect(body).toContain('%% canvas-size: 2000,1000');
    expect(body).toContain('subgraph skill_N0 ["Skill 1"]');
    expect(body).toContain('%% ui_N1 table-cells: [["a","b"],["c\\/d","e"]]'); // `/` escapas som Swift
    expect(body).toContain('linkStyle 0 interpolate stepAfter');
    expect(body).toContain('%% legend ui: Egna UI-element');
    await expectParses(body);
  });

  it('bakåtkant skrivs ALDRIG som `<--` (render-krasch-klassen, 💡#8)', () => {
    const doc: CanvasDoc = {
      shapes: [
        makeShape({ id: 'a', type: 'circle', position: { x: 0, y: 0 } }),
        makeShape({ id: 'b', type: 'circle', position: { x: 100, y: 0 } }),
      ],
      edges: [makeEdge({ id: 'e', from: 'a', to: 'b', direction: 'backward' })],
    };
    const body = generateMermaidBody(doc);
    expect(body).not.toContain('<--');
    expect(body).not.toContain('<-.-');
    // omvänd framåtpil: målet står först
    expect(body).toMatch(/ui_N1 --> ui_N0/);
  });
});
