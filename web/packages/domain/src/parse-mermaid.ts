// Tier 2-fallback: ren-mermaid-PARSERN — trogen TS-port av Swift
// MermaidParser.parseMermaid. Läser en mermaid-KROPP (fence-innehållet, utan
// state-JSON) tillbaka till CanvasDoc: nodrader, kantrader och ALLA `%%`-metadata-
// nycklar. Swift är facit — även udda beteenden speglas avsiktligt.
// Delar: text/mönster → parse-mermaid-text.ts · %%-meta → parse-mermaid-meta.ts ·
// auto-layout → parse-mermaid-layout.ts. REN TS, 0 beroenden.

import {
  type CanvasDoc,
  type EdgeConnection,
  type Point,
  type ShapeNode,
  SHAPE_TYPES,
  TEXT_STYLES,
  makeEdge,
  makeShape,
} from './model.js';
import { type NodeMeta, parseEdgeMeta, parseNodeMeta } from './parse-mermaid-meta.js';
import { autoLayoutPositions, flowDirectionIn } from './parse-mermaid-layout.js';
import { collectDeclaredNodes, collectRawEdges, categoryFor, leadingIdent } from './parse-mermaid-text.js';

export interface MermaidBodyExtras {
  /** Canvas-mått ur `%% canvas-size: w,h` (om raden finns). */
  canvasSize?: { width: number; height: number };
  /** Kollapsade GRENAR — kant-id:n (v63; inkl. migrerad nod-kollaps från äldre filer). */
  collapsedEdgeIds: Set<string>;
  /** `%% legend <kategori>: text` — kategori-rawValue → betydelse. */
  legend: Record<string, string>;
}

export interface ParsedMermaidBody {
  doc: CanvasDoc;
  extras: MermaidBodyExtras;
}

const isShapeType = (v: string) => (SHAPE_TYPES as readonly string[]).includes(v);
const isTextStyle = (v: string) => (TEXT_STYLES as readonly string[]).includes(v);

/**
 * Parsar en mermaid-KROPP (fence-innehållet) → CanvasDoc + extras.
 * Nod-id:n i dokumentet = mermaid-id:n (`<kategori>_N<index>`); kant-id:n = `edge_<i>`.
 * `opts.specType` (från frontmatter) styr v66-regeln: flow-filer utan explicit
 * riktning auto-layoutas LR (Swift läser detta ur hela markdown-filen).
 */
export function parseMermaidBody(body: string, opts?: { specType?: string }): ParsedMermaidBody {
  const block = body;
  const seen = new Set<string>();
  const nodes = collectDeclaredNodes(block, seen);

  // v61: %%-metadata gör blocket självbärande utan state-JSON.
  const meta = parseNodeMeta(block);

  // Kanter i ett AVSKALAT block (inline-deklarationer som `a["X"] --> b["Y"]` hittas då).
  const rawEdges = collectRawEdges(block);

  // v61: nakna id:n utan deklaration blir rektanglar med id:t som text.
  for (const raw of rawEdges) {
    for (const id of [raw.from, raw.to]) {
      if (seen.has(id)) continue;
      seen.add(id);
      nodes.push({ mermaidId: id, type: 'rectangle', label: id, category: categoryFor(id, undefined) });
    }
  }

  const edgeMeta = parseEdgeMeta(block);

  // v61/v66: auto-layout för noder utan `%% pos:`. Flow-filer utan explicit riktning → LR.
  let flowDirection = flowDirectionIn(block);
  if (flowDirection === 'td' && opts?.specType === 'flow') {
    const firstHeader = block.split('\n').map((l) => l.trim())
      .find((l) => l.toLowerCase().startsWith('flowchart') || l.toLowerCase().startsWith('graph'));
    const hasExplicit = firstHeader !== undefined
      && firstHeader.split(' ').filter((p) => p.length > 0).length >= 2;
    if (!hasExplicit) flowDirection = 'lr';
  }
  const autoPositions = autoLayoutPositions(
    nodes.map((n) => n.mermaidId),
    rawEdges.map((e) => ({ from: e.from, to: e.to })),
    flowDirection,
  );

  // v61.2: subgraph-medlemskap — rader mellan `subgraph X` och `end` är containerns barn.
  const membership = new Map<string, string>();
  let currentContainer: string | undefined;
  for (const rawLine of block.split('\n')) {
    const line = rawLine.trim();
    if (line === '') continue;
    if (line.startsWith('subgraph')) {
      const id = leadingIdent(line.slice('subgraph'.length).trim());
      currentContainer = id === '' ? undefined : id;
      continue;
    }
    if (line === 'end') { currentContainer = undefined; continue; }
    if (currentContainer === undefined || line.startsWith('%%')) continue;
    const nodeId = leadingIdent(line);
    if (nodeId !== '') membership.set(nodeId, currentContainer);
  }

  const legacyCollapsedShapeIds = new Set<string>();  // v63: migreras till grenar nedan
  const shapes: ShapeNode[] = nodes.map((n) => {
    const m: NodeMeta | undefined = meta.get(n.mermaidId);
    const pos: Point = m?.position ?? autoPositions.get(n.mermaidId) ?? { x: 200, y: 320 };
    // Dold etikett skrivs som " " i nod-syntaxen — återställ från %% name:
    const trimmedLabel = n.label.trim();
    const label = trimmedLabel === '' ? (m?.name ?? trimmedLabel) : n.label;
    // v67: explicit %% shape-type vinner över mermaid-kroppen.
    const type = m?.shapeTypeRaw !== undefined && isShapeType(m.shapeTypeRaw)
      ? (m.shapeTypeRaw as ShapeNode['type']) : n.type;
    const shape = makeShape({
      id: n.mermaidId,
      type,
      position: pos,
      label,
      showLabel: !(m?.hiddenLabel ?? false),
      sizeMultiplier: Math.max(0.01, m?.size ?? 1),
      note: m?.note ?? '',
      prompt: m?.prompt ?? '',
      category: n.category,
      rotation: m?.rotation ?? 0,
      textStyle: m?.textStyleRaw !== undefined && isTextStyle(m.textStyleRaw)
        ? (m.textStyleRaw as ShapeNode['textStyle']) : 'body',
      textAlignment: m?.textAlignRaw === 'leading' || m?.textAlignRaw === 'trailing'
        ? m.textAlignRaw : 'center',
      hasBullets: m?.hasBullets ?? false,
      hasNumberedList: m?.hasNumberedList ?? false,
      indentLevel: Math.max(0, m?.indentLevel ?? 0),
      locked: m?.locked ?? false,
      zLayer: m?.zLayer ?? 0,
    });
    if (m?.width !== undefined) shape.widthMultiplier = Math.max(0.01, m.width);
    if (m?.height !== undefined) shape.heightMultiplier = Math.max(0.01, m.height);
    if (m?.color !== undefined) shape.colorOverride = m.color;
    if (m?.stroke !== undefined) shape.strokeColorOverride = m.stroke;
    if (m?.link !== undefined) shape.linkNumber = m.link;
    if (m?.skillNumber !== undefined) shape.skillNumber = m.skillNumber;
    if (m?.tableRows !== undefined) shape.tableRows = m.tableRows;
    if (m?.tableCols !== undefined) shape.tableCols = m.tableCols;
    if (m?.tableCells !== undefined) shape.tableCells = m.tableCells;
    if (m?.packId !== undefined) shape.colorPackId = m.packId;
    // line-end skrivs absolut av generatorn → tillbaka till relativ offset
    if (m?.lineEndAbsolute !== undefined) {
      shape.lineEnd = { x: m.lineEndAbsolute.x - pos.x, y: m.lineEndAbsolute.y - pos.y };
    }
    if (m?.collapsed) legacyCollapsedShapeIds.add(n.mermaidId);
    return shape;
  });

  // v61.2: andra-pass — koppla barnen till sina containrar.
  const idSet = new Set(nodes.map((n) => n.mermaidId));
  nodes.forEach((n, i) => {
    const containerMid = membership.get(n.mermaidId);
    if (containerMid !== undefined && idSet.has(containerMid) && containerMid !== n.mermaidId) {
      shapes[i]!.childOfContainerId = containerMid;
    }
  });

  const edges: EdgeConnection[] = [];
  const collapsedEdgeIds = new Set<string>();
  rawEdges.forEach((raw, i) => {
    if (!idSet.has(raw.from) || !idSet.has(raw.to)) return;
    const startsWithArrow = raw.arrow.startsWith('<');
    const endsWithArrow = raw.arrow.endsWith('>');
    const direction = startsWithArrow && endsWithArrow ? 'bidirectional'
      : endsWithArrow ? 'forward'
      : startsWithArrow ? 'backward'
      : 'none';
    const edge = makeEdge({
      id: `edge_${edges.length}`,
      from: raw.from,
      to: raw.to,
      label: raw.label,
      direction,
      style: raw.arrow.includes('.') ? 'dashed' : 'solid',
      waypoints: edgeMeta.waypoints.get(i) ?? [],
      labelPlacement: edgeMeta.placements.get(i) ?? 'below',
      lineShape: edgeMeta.lineShapes.get(i) ?? 'curved',
    });
    const color = edgeMeta.colors.get(i);
    if (color !== undefined) edge.colorHex = color;
    const fromSide = edgeMeta.fromSides.get(i);
    if (fromSide !== undefined) edge.fromSide = fromSide;
    const toSide = edgeMeta.toSides.get(i);
    if (toSide !== undefined) edge.toSide = toSide;
    if (edgeMeta.collapsedIndices.has(i)) collapsedEdgeIds.add(edge.id);
    edges.push(edge);
  });

  // v63-migrering: gamla `%% <nod> collapsed` → nodens alla utgående grenar.
  for (const e of edges) {
    if (legacyCollapsedShapeIds.has(e.from)) collapsedEdgeIds.add(e.id);
  }

  // v66-migrering: linjer/pilar äger längd via lineEnd; gamla multipliers bakas in.
  for (const s of shapes) {
    if ((s.type === 'line' || s.type === 'arrow') && s.lineEnd) {
      const effW = s.widthMultiplier ?? s.sizeMultiplier;
      const effH = s.heightMultiplier ?? s.sizeMultiplier;
      if (effW !== 1 || effH !== 1) {
        s.lineEnd = { x: s.lineEnd.x * effW, y: s.lineEnd.y * effH };
        s.sizeMultiplier = 1;
        delete s.widthMultiplier;
        delete s.heightMultiplier;
      }
    }
  }

  // G1: canvas-måtten ur %%-raden (round-trippar i REN mermaid).
  const extras: MermaidBodyExtras = { collapsedEdgeIds, legend: {} };
  const cs = /%%\s*canvas-size:\s*([0-9.]+)\s*,\s*([0-9.]+)/.exec(block);
  if (cs) {
    const w = Number(cs[1]);
    const h = Number(cs[2]);
    if (Number.isFinite(w) && Number.isFinite(h)) extras.canvasSize = { width: w, height: h };
  }
  // v66: legend-rader (kategori → Kims betydelse-text).
  for (const m of block.matchAll(/%%\s+legend\s+(\w+):\s+(.+)/g)) {
    extras.legend[m[1]!] = m[2]!.trim();
  }

  return { doc: { shapes, edges }, extras };
}
