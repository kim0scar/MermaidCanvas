// GULD-ORAKLET: fixturen native-v49-modern.md innehåller RIKTIG Swift-genererad mermaid-kropp
// (Kims 129-formers dokument). Vi genererar kroppen på nytt ur filens EGEN state-JSON och
// kräver att %%-metadata-raderna matchar fixturens — samma rader, samma format, samma antal.
import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { generateMermaidBody, parseCanvasFile, parseNativeState } from '../src/index.js';

const md = readFileSync(
  fileURLToPath(new URL('./fixtures/native-v49-modern.md', import.meta.url)),
  'utf8',
);
const parsed = parseCanvasFile(md);
const native = parseNativeState(parsed.stateJson!);
const canvas = native.extras.canvas as { width: number; height: number };

const body = generateMermaidBody(native.doc, {
  canvasSize: { width: canvas.width, height: canvas.height },
  collapsedEdgeIds: new Set(
    native.doc.edges.filter((e) => native.rawEdges.get(e.id)?.collapsed === true).map((e) => e.id),
  ),
  legend: (native.extras.legend ?? {}) as Record<string, string>,
});

/** Alla %%-metadata-rader, trimmade (init-direktivet räknas inte). */
function metaLines(text: string): string[] {
  return text
    .split('\n')
    .map((l) => l.trim())
    .filter((l) => l.startsWith('%%') && !l.startsWith('%%{'));
}

/** Multiset: rad → antal förekomster. */
function counted(lines: string[]): Map<string, number> {
  const m = new Map<string, number>();
  for (const l of lines) m.set(l, (m.get(l) ?? 0) + 1);
  return m;
}

const fixtureLines = counted(metaLines(parsed.mermaid));
const webLines = counted(metaLines(body));

/** Rader webben emitterar UTÖVER fixturen (multiset-differens). */
function surplusLines(): string[] {
  const extras: string[] = [];
  for (const [line, n] of webLines) {
    const surplus = n - (fixtureLines.get(line) ?? 0);
    for (let k = 0; k < surplus; k++) extras.push(line);
  }
  return extras;
}

// KÄND-DIFF (ärlig, krympande — får ALDRIG växa): fixturen genererades av Swift-appen v49
// (2026-05-22); porten följer DAGENS Swift (1.5.7). Dagens Swift emitterar därför exakt tre
// rad-klasser som fixturen saknar — nyare funktioner, inte format-avvikelser:
//   1) `%% <id> name: <etikett>`  (v60) — en per nod med icke-tom etikett
//   2) `%% legend <kategori>: …`  (v66/v71-autofyll) — en per använd kategori (här: bara ui)
//   3) `%% canvas-size: w,h`      (G1)
// Regenereras fixturen med modern app → ta bort klassen här och låt exakt-matchen ta över.
const KNOWN_DIFF = [/^%% \S+ name: /, /^%% legend \S+: /, /^%% canvas-size: /] as const;

describe('guld-oraklet: %%-rader mot riktig Swift-genererad fixture', () => {
  it('VARJE %%-rad i fixturen återskapas exakt (format + antal)', () => {
    for (const [line, n] of fixtureLines) {
      expect(webLines.get(line) ?? 0, `saknad/avvikande rad: ${line}`).toBe(n);
    }
  });

  it('rader utöver fixturen tillhör ENBART känd-diff-klasserna', () => {
    for (const line of surplusLines()) {
      expect(KNOWN_DIFF.some((re) => re.test(line)), `okänd extra-rad: ${line}`).toBe(true);
    }
  });

  it('känd-diffen är exakt tre klasser med förväntat antal (krymper, växer aldrig)', () => {
    const extras = surplusLines();
    const names = extras.filter((l) => KNOWN_DIFF[0].test(l));
    const legends = extras.filter((l) => KNOWN_DIFF[1].test(l));
    const canvasSizes = extras.filter((l) => KNOWN_DIFF[2].test(l));
    const labeledNodes = native.doc.shapes.filter((s) => s.type !== 'container' && s.label !== '');
    expect(names).toHaveLength(labeledNodes.length);
    expect(legends).toEqual(['%% legend ui: UI-element — text syns på skärmen.']);
    expect(canvasSizes).toEqual([`%% canvas-size: ${canvas.width},${canvas.height}`]);
    expect(names.length + legends.length + canvasSizes.length).toBe(extras.length);
  });
});
