// Tier 2 (ren mermaid-kropp) — FAS 0-DELMÄNGD: renderbar mermaid för grundformer + kanter.
// Full byte-paritet med Swift MermaidGenerator.swift + escaping + alla former + classDef-färger +
// legender + linkStyle kommer i nästa steg (då aktiveras Swift↔TS golden-diff-grinden).
// Den BLOCKERANDE grinden denna fas är state-JSON-round-trip (Tier 1), inte denna fil.

import type { CanvasDoc, EdgeConnection, ShapeNode, ShapeType } from './model.js';

const HEADER = '%%{init: {"flowchart": {"curve": "basis"}}}%%\nflowchart TD';

/** Native mermaid-form-omslag per typ (matchar all-shapes.mmd). Ej-native → rektangel + shape-type-bärare. */
function wrapNode(mid: string, type: ShapeType, label: string, cat: string): string {
  const q = `"${escapeLabel(label)}"`;
  switch (type) {
    case 'circle': return `${mid}((${q})):::${cat}`;
    case 'diamond': return `${mid}{${q}}:::${cat}`;
    case 'pill': return `${mid}([${q}]):::${cat}`;
    case 'cylinder': return `${mid}[(${q})]:::${cat}`;
    // rektangel + alla ej-native former renderas som närmaste native (rektangel), identitet i %% shape-type
    default: return `${mid}[${q}]:::${cat}`;
  }
}

/** Former som INTE har en egen native mermaid-form → bär sin identitet i %% shape-type. */
const NON_NATIVE: ReadonlySet<ShapeType> = new Set([
  'table', 'link', 'line', 'arrow', 'square', 'processArrow',
  'container', 'octagon', 'phoneFrame', 'triangle', 'emoji',
]);

/** Minimal label-escaping (mermaid entiteter + radbrytning). Full paritet portas med golden-diff. */
function escapeLabel(s: string): string {
  return s.replace(/"/g, '#quot;').replace(/\r?\n/g, '<br/>');
}

/**
 * Kant-tråd + ev. sidbyte. Lärdomen från native (💡#8): `<--` PARSAR men kraschar riktig
 * mermaid-RENDER → bakåtkant skrivs som OMVÄND framåtpil (swap), aldrig `<--`.
 */
function edgeWire(e: EdgeConnection): { wire: string; swap: boolean } {
  const dashed = e.style === 'dashed';
  switch (e.direction) {
    case 'forward': return { wire: dashed ? '-.->' : '-->', swap: false };
    case 'backward': return { wire: dashed ? '-.->' : '-->', swap: true };
    case 'bidirectional': return { wire: dashed ? '<-.->' : '<-->', swap: false };
    case 'none': return { wire: dashed ? '-.-' : '---', swap: false };
  }
}

function edgeArrow(e: EdgeConnection): { text: string; swap: boolean } {
  const { wire, swap } = edgeWire(e);
  return { text: e.label ? `${wire}|"${escapeLabel(e.label)}"|` : wire, swap };
}

/**
 * Generera Tier 2-mermaidkroppen (renderbar delmängd). `idFor` mappar ShapeNode → mermaid-nod-id
 * (`<kategori>_N<index>`), samma stil som Swift-generatorn.
 */
export function generateMermaidBody(doc: CanvasDoc): string {
  const idFor = new Map<string, string>();
  doc.shapes.forEach((s, i) => idFor.set(s.id, `${s.category}_N${i}`));

  const lines: string[] = [HEADER];

  for (const s of doc.shapes) {
    const mid = idFor.get(s.id)!;
    lines.push(`    ${wrapNode(mid, s.type, s.label, s.category)}`);
    if (NON_NATIVE.has(s.type)) lines.push(`    %% ${mid} shape-type: ${s.type}`);
    lines.push(`    %% ${mid} pos: ${round(s.position.x)},${round(s.position.y)}`);
    lines.push(`    %% ${mid} name: ${s.label.replace(/\r?\n/g, ' ')}`);
  }

  for (const e of doc.edges) {
    const from = idFor.get(e.from);
    const to = idFor.get(e.to);
    if (!from || !to) continue;
    const { text, swap } = edgeArrow(e);
    lines.push(swap ? `    ${to} ${text} ${from}` : `    ${from} ${text} ${to}`);
  }

  const usedCats = new Set(doc.shapes.map((s) => s.category));
  for (const cat of usedCats) {
    // FAS 0 platshållar-classDef (parsebar). Exakta per-kategori-färger portas med golden-diff.
    lines.push(`    classDef ${cat} fill:#ffffff,stroke:#1e293b,color:#111827;`);
  }

  return lines.join('\n') + '\n';
}

function round(n: number): number {
  return Math.round(n);
}
