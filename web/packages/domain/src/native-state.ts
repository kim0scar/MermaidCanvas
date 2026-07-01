// Det RIKTIGA state-JSON-schemat — samma som Swift-appen skriver/läser
// (MermaidGenerator+StateJSON.swift): toppnivå {canvas, specType, platform, shapePacks,
// nodes, edges, legend?}, noder med mermaid-id ("ui_N0") + platta x/y + villkorliga fält
// (skrivs bara när de avviker från default). REN TS, 0 beroenden.
//
// Rå-bevarande princip (noll-avvikelse, regel 3): vi börjar ALLTID från filens råa dict
// och ändrar bara de fält canvasen faktiskt styr. Okända/omodellerade nycklar (subCanvas,
// collapsed, framtida fält) följer med orörda. Byte-paritet mot Swift-emissionen bevisas
// i W3 (golden-diff); W2-grinden är schema-KOMPATIBILITET: riktiga filer läses, och det
// vi skriver läses av native-parsern + oss själva förlustfritt.

import {
  type CanvasDoc,
  type EdgeConnection,
  type ShapeNode,
  SHAPE_CATEGORIES,
  SHAPE_TYPES,
  TEXT_STYLES,
  makeEdge,
  makeShape,
} from './model.js';

type RawDict = Record<string, unknown>;

/** Parsead native-fil: typad modell + rå-dicts för förlustfri återskrivning. */
export interface NativeState {
  doc: CanvasDoc;
  /** Toppnivå-nycklar utom nodes/edges (canvas, specType, platform, shapePacks, legend, okända). */
  extras: RawDict;
  /** Rå nod-dict per shape-id (sessionens id = filens mermaid-id vid inläsning). */
  rawNodes: Map<string, RawDict>;
  /** Rå kant-dict per session-kant-id. */
  rawEdges: Map<string, RawDict>;
}

function asNumber(v: unknown, fallback: number): number {
  return typeof v === 'number' && Number.isFinite(v) ? v : fallback;
}
function asString(v: unknown, fallback: string): string {
  return typeof v === 'string' ? v : fallback;
}
function asBool(v: unknown, fallback: boolean): boolean {
  return typeof v === 'boolean' ? v : fallback;
}

function oneOf<T extends string>(v: unknown, allowed: readonly T[], fallback: T): T {
  return typeof v === 'string' && (allowed as readonly string[]).includes(v) ? (v as T) : fallback;
}

/** Läs en nod-dict → ShapeNode (frånvarande fält = Swift-defaults via makeShape). */
function parseNode(n: RawDict): ShapeNode {
  const type = oneOf(n.type, SHAPE_TYPES, 'rectangle');
  const shape = makeShape({
    id: asString(n.id, ''),
    type,
    position: { x: asNumber(n.x, 0), y: asNumber(n.y, 0) },
    label: asString(n.label, ''),
    category: oneOf(n.category, SHAPE_CATEGORIES, 'ui'),
    showLabel: asBool(n.showLabel, true),
    sizeMultiplier: asNumber(n.size, 1),
    rotation: asNumber(n.rotation, 0),
    note: asString(n.note, ''),
    textStyle: oneOf(n.textStyle, TEXT_STYLES, 'body'),
    textAlignment: oneOf(n.textAlignment, ['leading', 'center', 'trailing'] as const, 'center'),
    hasBullets: asBool(n.hasBullets, false),
    hasNumberedList: asBool(n.hasNumberedList, false),
    indentLevel: asNumber(n.indentLevel, 0),
    bold: asBool(n.bold, false),
    italic: asBool(n.italic, false),
    underline: asBool(n.underline, false),
    locked: asBool(n.locked, false),
    zLayer: asNumber(n.zLayer, 0),
    prompt: asString(n.prompt, ''),
  });
  if (typeof n.color === 'string') shape.colorOverride = n.color;
  if (typeof n.strokeColor === 'string') shape.strokeColorOverride = n.strokeColor;
  if (typeof n.linkNumber === 'number') shape.linkNumber = n.linkNumber;
  if (typeof n.skillNumber === 'number') shape.skillNumber = n.skillNumber;
  if (typeof n.tableRows === 'number') shape.tableRows = n.tableRows;
  if (typeof n.tableCols === 'number') shape.tableCols = n.tableCols;
  if (Array.isArray(n.tableCells)) shape.tableCells = n.tableCells as string[][];
  if (typeof n.colorPackId === 'string') shape.colorPackId = n.colorPackId;
  if (typeof n.widthMultiplier === 'number') shape.widthMultiplier = n.widthMultiplier;
  if (typeof n.heightMultiplier === 'number') shape.heightMultiplier = n.heightMultiplier;
  const le = n.lineEnd as RawDict | undefined;
  if (le && typeof le.x === 'number' && typeof le.y === 'number') {
    shape.lineEnd = { x: le.x, y: le.y };
  }
  if (typeof n.childOfContainerId === 'string') shape.childOfContainerId = n.childOfContainerId;
  if (n.subCanvas !== undefined) shape.subCanvas = n.subCanvas;
  return shape;
}

function parseEdge(e: RawDict, index: number): EdgeConnection {
  const edge = makeEdge({
    id: `edge_${index}`,
    from: asString(e.from, ''),
    to: asString(e.to, ''),
    label: asString(e.label, ''),
    direction: oneOf(e.direction, ['forward', 'backward', 'bidirectional', 'none'] as const, 'forward'),
    style: oneOf(e.style, ['solid', 'dashed'] as const, 'solid'),
    labelPlacement: oneOf(e.labelPlacement, ['above', 'below'] as const, 'below'),
    lineShape: oneOf(e.lineShape, ['straight', 'curved', 'orthogonal'] as const, 'curved'),
  });
  if (Array.isArray(e.waypoints)) {
    edge.waypoints = (e.waypoints as RawDict[])
      .filter((w) => typeof w.x === 'number' && typeof w.y === 'number')
      .map((w) => ({ x: w.x as number, y: w.y as number }));
  }
  if (typeof e.color === 'string') edge.colorHex = e.color;
  if (typeof e.fromSide === 'string') edge.fromSide = e.fromSide as EdgeConnection['fromSide'];
  if (typeof e.toSide === 'string') edge.toSide = e.toSide as EdgeConnection['toSide'];
  return edge;
}

/**
 * Är detta en LEGACY-fil (äldre app-version)? Kännetecken: kanter med `bidirectional`-nyckel
 * (före `direction`) eller nod-typer som inte längre finns (t.ex. `text`). Legacy-filer öppnas
 * bara i visaren — redigering utan schema-migrering skulle tyst mutera data (regel 3-brott).
 * Migreringen portas i W3 (parser-porten).
 */
export function isLegacyState(stateJson: string): boolean {
  let root: RawDict;
  try {
    root = JSON.parse(stateJson) as RawDict;
  } catch {
    return true;
  }
  const nodes = Array.isArray(root.nodes) ? (root.nodes as RawDict[]) : [];
  const edges = Array.isArray(root.edges) ? (root.edges as RawDict[]) : [];
  if (edges.some((e) => 'bidirectional' in e)) return true;
  if (nodes.some((n) => typeof n.type === 'string' && !(SHAPE_TYPES as readonly string[]).includes(n.type))) return true;
  return false;
}

/** Parsa state-JSON-texten (innehållet mellan markörerna) till NativeState. Kastar vid trasig JSON. */
export function parseNativeState(stateJson: string): NativeState {
  const root = JSON.parse(stateJson) as RawDict;
  const rawNodeArr = Array.isArray(root.nodes) ? (root.nodes as RawDict[]) : [];
  const rawEdgeArr = Array.isArray(root.edges) ? (root.edges as RawDict[]) : [];

  const shapes: ShapeNode[] = [];
  const rawNodes = new Map<string, RawDict>();
  rawNodeArr.forEach((n, i) => {
    const shape = parseNode(n);
    if (!shape.id) shape.id = `node_${i}`;
    shapes.push(shape);
    rawNodes.set(shape.id, n);
  });

  const edges: EdgeConnection[] = [];
  const rawEdges = new Map<string, RawDict>();
  rawEdgeArr.forEach((e, i) => {
    const edge = parseEdge(e, i);
    edges.push(edge);
    rawEdges.set(edge.id, e);
  });

  const extras: RawDict = {};
  for (const [k, v] of Object.entries(root)) {
    if (k !== 'nodes' && k !== 'edges') extras[k] = v;
  }
  return { doc: { shapes, edges }, extras, rawNodes, rawEdges };
}

/** Mermaid-id per form: `<kategori>_N<index>` — exakt som Swift makeMermaidIds (idPrefix = rawValue). */
export function makeMermaidIds(shapes: ShapeNode[]): Map<string, string> {
  const ids = new Map<string, string>();
  shapes.forEach((s, i) => ids.set(s.id, `${s.category}_N${i}`));
  return ids;
}

/** Sätt/ta bort nyckel enligt Swifts villkorliga emission (villkor falskt → nyckeln bort). */
function setIf(d: RawDict, key: string, cond: boolean, value: () => unknown): void {
  if (cond) d[key] = value();
  else delete d[key];
}

/** Bygg nod-dicten för en form — port av Swift canvasStateJSON nod-emission, rå-först. */
function emitNode(shape: ShapeNode, mid: string, raw: RawDict | undefined, mids: Map<string, string>): RawDict {
  const n: RawDict = { ...(raw ?? {}) };
  n.id = mid;
  n.x = shape.position.x;
  n.y = shape.position.y;
  n.label = shape.label;
  n.type = shape.type;
  n.category = shape.category;
  n.showLabel = shape.showLabel;
  n.size = shape.sizeMultiplier;
  n.rotation = shape.rotation;
  n.note = shape.note;
  setIf(n, 'color', shape.colorOverride !== undefined, () => shape.colorOverride);
  setIf(n, 'strokeColor', shape.strokeColorOverride !== undefined, () => shape.strokeColorOverride);
  setIf(n, 'linkNumber', shape.linkNumber !== undefined, () => shape.linkNumber);
  setIf(n, 'skillNumber', shape.skillNumber !== undefined, () => shape.skillNumber);
  const hasTable =
    shape.type === 'table' ||
    shape.tableRows !== undefined ||
    shape.tableCols !== undefined ||
    shape.tableCells !== undefined;
  setIf(n, 'tableRows', hasTable, () => shape.tableRows ?? 3);
  setIf(n, 'tableCols', hasTable, () => shape.tableCols ?? 3);
  setIf(n, 'tableCells', hasTable && !!shape.tableCells && shape.tableCells.length > 0, () => shape.tableCells);
  setIf(n, 'textStyle', shape.textStyle !== 'body', () => shape.textStyle);
  setIf(n, 'colorPackId', shape.colorPackId !== undefined, () => shape.colorPackId);
  setIf(n, 'widthMultiplier', shape.widthMultiplier !== undefined, () => shape.widthMultiplier);
  setIf(n, 'heightMultiplier', shape.heightMultiplier !== undefined, () => shape.heightMultiplier);
  setIf(n, 'lineEnd', shape.lineEnd !== undefined, () => ({ x: shape.lineEnd!.x, y: shape.lineEnd!.y }));
  setIf(n, 'textAlignment', shape.textAlignment !== 'center', () => shape.textAlignment);
  setIf(n, 'hasBullets', shape.hasBullets, () => true);
  setIf(n, 'hasNumberedList', shape.hasNumberedList, () => true);
  setIf(n, 'indentLevel', shape.indentLevel > 0, () => shape.indentLevel);
  setIf(n, 'bold', shape.bold, () => true);
  setIf(n, 'italic', shape.italic, () => true);
  setIf(n, 'underline', shape.underline, () => true);
  setIf(n, 'locked', shape.locked, () => true);
  setIf(n, 'zLayer', shape.zLayer !== 0, () => shape.zLayer);
  setIf(n, 'prompt', shape.prompt !== '', () => shape.prompt);
  const parentMid = shape.childOfContainerId ? mids.get(shape.childOfContainerId) ?? shape.childOfContainerId : undefined;
  setIf(n, 'childOfContainerId', parentMid !== undefined, () => parentMid);
  setIf(n, 'subCanvas', shape.subCanvas !== undefined, () => shape.subCanvas);
  return n;
}

/** Bygg kant-dicten — port av Swift kant-emission, rå-först ("collapsed" m.fl. följer med rått). */
function emitEdge(edge: EdgeConnection, raw: RawDict | undefined, mids: Map<string, string>): RawDict | null {
  const from = mids.get(edge.from);
  const to = mids.get(edge.to);
  if (!from || !to) return null;
  const e: RawDict = { ...(raw ?? {}) };
  e.from = from;
  e.to = to;
  e.label = edge.label;
  e.direction = edge.direction;
  e.style = edge.style;
  setIf(e, 'waypoints', edge.waypoints.length > 0, () => edge.waypoints.map((w) => ({ x: w.x, y: w.y })));
  setIf(e, 'labelPlacement', edge.labelPlacement !== 'below', () => edge.labelPlacement);
  setIf(e, 'color', edge.colorHex !== undefined, () => edge.colorHex);
  setIf(e, 'fromSide', edge.fromSide !== undefined, () => edge.fromSide);
  setIf(e, 'toSide', edge.toSide !== undefined, () => edge.toSide);
  setIf(e, 'lineShape', edge.lineShape !== 'curved', () => edge.lineShape);
  return e;
}

/** Defaults för en NY fil skapad i webben (ingen iphoneFrame — Swift-parsern tål frånvaro). */
export function newFileExtras(canvasWidth = 1200, canvasHeight = 800): RawDict {
  return {
    canvas: {
      width: canvasWidth,
      height: canvasHeight,
      shapeBaseWidth: 120,
      shapeBaseHeight: 80,
      unit: 'pt',
    },
    specType: 'general',
    platform: 'blank',
    shapePacks: ['basic'],
  };
}

/**
 * Serialisera till state-JSON-text (sorterade nycklar på alla nivåer + 2-space indrag —
 * speglar Swifts JSONSerialization [.prettyPrinted, .sortedKeys]).
 */
export function generateNativeState(doc: CanvasDoc, state?: Pick<NativeState, 'extras' | 'rawNodes' | 'rawEdges'>): string {
  const mids = makeMermaidIds(doc.shapes);
  const nodes = doc.shapes.map((s) => emitNode(s, mids.get(s.id)!, state?.rawNodes.get(s.id), mids));
  const edges = doc.edges
    .map((e) => emitEdge(e, state?.rawEdges.get(e.id), mids))
    .filter((e): e is RawDict => e !== null);
  const root: RawDict = { ...(state?.extras ?? newFileExtras()), nodes, edges };
  return stableStringify(root, 0);
}

/**
 * Bind om NativeState efter en sparning: rå-dicts ur den NYSS genererade state-texten,
 * nycklade på SESSIONENS id:n (dokumentets ordning == nodes/edges-arrayernas ordning).
 * Utan detta skulle andra sparningen tappa okända rå-fält (rawNodes vore nycklade på
 * gamla fil-id:n som inte längre matchar sessionens).
 */
export function rebindNativeState(doc: CanvasDoc, stateJson: string): NativeState {
  const root = JSON.parse(stateJson) as RawDict;
  const nodes = Array.isArray(root.nodes) ? (root.nodes as RawDict[]) : [];
  const edges = Array.isArray(root.edges) ? (root.edges as RawDict[]) : [];
  const rawNodes = new Map<string, RawDict>();
  doc.shapes.forEach((s, i) => {
    if (nodes[i]) rawNodes.set(s.id, nodes[i]!);
  });
  const rawEdges = new Map<string, RawDict>();
  doc.edges.forEach((e, i) => {
    if (edges[i]) rawEdges.set(e.id, edges[i]!);
  });
  const extras: RawDict = {};
  for (const [k, v] of Object.entries(root)) {
    if (k !== 'nodes' && k !== 'edges') extras[k] = v;
  }
  return { doc, extras, rawNodes, rawEdges };
}

/** JSON med alfabetiskt sorterade nycklar + 2-space pretty (alla nivåer). */
function stableStringify(value: unknown, depth: number): string {
  const pad = '  '.repeat(depth);
  const padIn = '  '.repeat(depth + 1);
  if (value === null || typeof value === 'number' || typeof value === 'boolean') {
    return JSON.stringify(value);
  }
  if (typeof value === 'string') return JSON.stringify(value);
  if (Array.isArray(value)) {
    if (value.length === 0) return '[]';
    const items = value.map((v) => padIn + stableStringify(v, depth + 1));
    return `[\n${items.join(',\n')}\n${pad}]`;
  }
  if (typeof value === 'object') {
    const entries = Object.entries(value as RawDict).filter(([, v]) => v !== undefined);
    if (entries.length === 0) return '{}';
    entries.sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0));
    const items = entries.map(([k, v]) => `${padIn}${JSON.stringify(k)}: ${stableStringify(v, depth + 1)}`);
    return `{\n${items.join(',\n')}\n${pad}}`;
  }
  return JSON.stringify(value ?? null);
}
