// Tier 2 (ren mermaid-kropp). %%-METADATAN har full Swift-paritet — alla carrier-nycklar
// emitteras med Swifts villkor/format/ordning (se generate-meta.ts + guld-oraklet
// test/generate-golden.test.ts mot riktig Swift-genererad fixture). NOD-KROPPARNA och
// classDef-färgerna är fortfarande Fas 0-delmängd (byte-paritet portas med golden-diff-grinden).
// Webben genererar utan iPhone-ram (= Swifts specType general/flow-väg).

import type { CanvasDoc, EdgeConnection, ShapeType } from './model.js';
import { SHAPE_CATEGORIES } from './model.js';
import {
  containerMetaLines,
  edgeMetaLines,
  legendLines,
  nodeMetaLines,
  swiftRound,
} from './generate-meta.js';

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

/** App-nivå-indata som inte bor i CanvasDoc (Swift generate()-parametrarna utöver shapes/edges). */
export interface GenerateMermaidOptions {
  /** Canvas-måtten (G1). Emitteras bara när båda är > 0, som Swift. */
  canvasSize?: { width: number; height: number };
  /** Kant-id (sessionens) vars gren är kollapsad. */
  collapsedEdgeIds?: ReadonlySet<string>;
  /** Manuell legend-text per kategori (LegendPanel) — vinner över autofyllens standardtext. */
  legend?: Readonly<Record<string, string>>;
}

/**
 * Generera Tier 2-mermaidkroppen. `idFor` mappar ShapeNode → mermaid-nod-id
 * (`<kategori>_N<index>`), samma stil som Swift-generatorn.
 */
export function generateMermaidBody(doc: CanvasDoc, opts: GenerateMermaidOptions = {}): string {
  // Tom canvas → bara header, inget diagnostiskt meddelande (som Swift v32).
  if (doc.shapes.length === 0) return HEADER + '\n';

  const idFor = new Map<string, string>();
  doc.shapes.forEach((s, i) => idFor.set(s.id, `${s.category}_N${i}`));

  const lines: string[] = [HEADER];
  const cs = opts.canvasSize;
  if (cs && cs.width > 0 && cs.height > 0) {
    lines.push(`    %% canvas-size: ${swiftRound(cs.width)},${swiftRound(cs.height)}`);
  }
  const indent = '    ';

  // Noder — alla utom containrar (containrar emitteras nedan som subgraph, som Swift).
  for (const s of doc.shapes) {
    if (s.type === 'container') continue;
    const mid = idFor.get(s.id)!;
    // Tom/dold etikett skrivs som blank (som Swift) — `[""]` parsar inte i riktig mermaid;
    // riktiga etiketten bärs av %% name-raden.
    const label = s.showLabel ? (s.label === '' ? ' ' : s.label) : ' ';
    lines.push(`${indent}${wrapNode(mid, s.type, label, s.category)}`);
    lines.push(...nodeMetaLines(s, mid, indent));
  }

  // Containrar → subgraph-block. Barnen är den EXPLICITA childOfContainerId-kopplingen
  // (Swift v73: positions-gissning gav mermaid/JSON-inkonsistens). Noderna är redan
  // definierade ovan — subgraphen refererar dem.
  for (const c of doc.shapes) {
    if (c.type !== 'container') continue;
    const cid = idFor.get(c.id)!;
    lines.push(`${indent}subgraph ${cid} ["${escapeLabel(c.label === '' ? 'Grupp' : c.label)}"]`);
    for (const child of doc.shapes) {
      if (child.id === c.id || child.type === 'container' || child.childOfContainerId !== c.id) continue;
      lines.push(`${indent}    ${idFor.get(child.id)!}`);
    }
    lines.push(`${indent}end`);
    lines.push(...containerMetaLines(c, cid, indent));
  }

  // Kanter: `i` = app-index (round-trip via e<i>), `me` = mermaids kant-räknare (linkStyle).
  let me = 0;
  doc.edges.forEach((e, i) => {
    const from = idFor.get(e.from);
    const to = idFor.get(e.to);
    if (!from || !to) return;
    const { text, swap } = edgeArrow(e);
    lines.push(swap ? `${indent}${to} ${text} ${from}` : `${indent}${from} ${text} ${to}`);
    lines.push(...edgeMetaLines(e, i, me, opts.collapsedEdgeIds?.has(e.id) ?? false, indent));
    me += 1;
  });

  // Legend (v71-autofyll) — översätter varje använd kategori för en läsare/AI.
  lines.push('');
  lines.push(...legendLines(doc.shapes, opts.legend ?? {}));

  // classDef per använd kategori, i ShapeCategory-ordning (som Swift).
  lines.push('');
  const usedCats = new Set(doc.shapes.map((s) => s.category));
  for (const cat of SHAPE_CATEGORIES) {
    if (!usedCats.has(cat)) continue;
    // FAS 0 platshållar-classDef (parsebar). Exakta per-kategori-färger portas med golden-diff.
    lines.push(`    classDef ${cat} fill:#ffffff,stroke:#1e293b,color:#111827;`);
  }

  return lines.join('\n') + '\n';
}
