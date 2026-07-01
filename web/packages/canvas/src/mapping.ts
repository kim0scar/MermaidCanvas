// Domän ↔ tldraw-records — REN datamappning (ingen Editor, Node-testbar).
//
// Princip (noll-avvikelse): tldraw är bara REDIGERINGS-modellen; domänen är sanning.
// Varje record bär sin domän-nod i `meta.domain` (= senast sparade läget). Vid läsning
// jämförs tldraw-värdena mot det FÖRVÄNTADE (beräknat ur meta.domain) — bara det som
// faktiskt ändrats skrivs tillbaka i modellen. Orörda fält förblir byte-exakta.
import {
  makeEdge,
  makeShape,
  type CanvasDoc,
  type EdgeConnection,
  type EdgeDirection,
  type ShapeNode,
  type ShapeType,
} from '@v2e/domain';
import {
  createBindingId,
  createShapeId,
  type TLGeoShapeGeoStyle,
  type TLRichText,
  type TLShapeId,
} from '@tldraw/tlschema';
import { BASE_SIZES, effectiveSize } from './sizes.js';
import { plainToRich, richToPlain } from './richtext.js';

/** Närmaste tldraw-geo per form-typ (rendering-approximation; identiteten bor i meta.domain). */
export const GEO_FOR_TYPE = {
  circle: 'ellipse',
  rectangle: 'rectangle',
  diamond: 'diamond',
  table: 'rectangle',
  link: 'rectangle',
  pill: 'oval',
  line: 'rectangle',
  arrow: 'arrow-right',
  square: 'rectangle',
  processArrow: 'arrow-right',
  container: 'rectangle',
  octagon: 'octagon',
  phoneFrame: 'rectangle',
  triangle: 'triangle',
  cylinder: 'rectangle',
  emoji: 'rectangle',
} as const satisfies Record<ShapeType, TLGeoShapeGeoStyle>;

/** Form-typ för NYA former ritade i tldraw (bara MVP-verktygen exponeras i UI:t). */
export function typeForGeo(geo: string): ShapeType {
  if (geo === 'ellipse') return 'circle';
  if (geo === 'diamond') return 'diamond';
  return 'rectangle';
}

const DEG_TO_RAD = Math.PI / 180;

type Meta = { domain?: unknown; order?: number };

export interface GeoRecord {
  id: TLShapeId;
  type: 'geo';
  x: number;
  y: number;
  rotation: number;
  props: {
    geo: TLGeoShapeGeoStyle;
    w: number;
    h: number;
    richText: TLRichText;
    fill: 'none' | 'semi';
    color: string;
    dash: 'solid' | 'dashed';
  };
  meta: Meta;
}

export interface ArrowRecord {
  id: TLShapeId;
  type: 'arrow';
  x: number;
  y: number;
  props: {
    start: { x: number; y: number };
    end: { x: number; y: number };
    arrowheadStart: 'none' | 'arrow';
    arrowheadEnd: 'none' | 'arrow';
    dash: 'solid' | 'dashed';
    richText: TLRichText;
    color: string;
  };
  meta: Meta;
}

export interface BindingRecord {
  id: ReturnType<typeof createBindingId>;
  type: 'arrow';
  fromId: TLShapeId;
  toId: TLShapeId;
  props: {
    terminal: 'start' | 'end';
    normalizedAnchor: { x: number; y: number };
    isExact: boolean;
    isPrecise: boolean;
  };
}

/** JSON-ren kopia (tar bort undefined-fält — tldraw-meta tillåter bara JSON). */
function cleanJson<T>(v: T): T {
  return JSON.parse(JSON.stringify(v)) as T;
}

export function tlShapeId(domainId: string): TLShapeId {
  return createShapeId(`n-${domainId}`);
}
export function tlArrowId(domainEdgeId: string): TLShapeId {
  return createShapeId(`e-${domainEdgeId}`);
}

export function shapeToRecord(node: ShapeNode, order: number): GeoRecord {
  const { w, h } = effectiveSize(node);
  const isFrame = node.type === 'container' || node.type === 'phoneFrame';
  return {
    id: tlShapeId(node.id),
    type: 'geo',
    x: node.position.x - w / 2,
    y: node.position.y - h / 2,
    rotation: node.rotation * DEG_TO_RAD,
    props: {
      geo: GEO_FOR_TYPE[node.type],
      w,
      h,
      richText: plainToRich(node.showLabel ? node.label : ''),
      fill: isFrame ? 'none' : 'semi',
      color: 'blue',
      dash: 'solid',
    },
    meta: { domain: cleanJson(node), order },
  };
}

function headsFor(direction: EdgeDirection): { start: 'none' | 'arrow'; end: 'none' | 'arrow' } {
  switch (direction) {
    case 'forward': return { start: 'none', end: 'arrow' };
    case 'backward': return { start: 'arrow', end: 'none' };
    case 'bidirectional': return { start: 'arrow', end: 'arrow' };
    case 'none': return { start: 'none', end: 'none' };
  }
}

function directionForHeads(start: string, end: string): EdgeDirection {
  const s = start !== 'none';
  const e = end !== 'none';
  if (s && e) return 'bidirectional';
  if (s) return 'backward';
  if (e) return 'forward';
  return 'none';
}

export function edgeToRecords(
  edge: EdgeConnection,
  order: number,
  centerOf: (domainId: string) => { x: number; y: number } | undefined,
): { arrow: ArrowRecord; bindings: BindingRecord[] } {
  const from = centerOf(edge.from) ?? { x: 0, y: 0 };
  const to = centerOf(edge.to) ?? { x: 100, y: 100 };
  const heads = headsFor(edge.direction);
  const arrowId = tlArrowId(edge.id);
  const arrow: ArrowRecord = {
    id: arrowId,
    type: 'arrow',
    x: 0,
    y: 0,
    props: {
      start: from,
      end: to,
      arrowheadStart: heads.start,
      arrowheadEnd: heads.end,
      dash: edge.style === 'dashed' ? 'dashed' : 'solid',
      richText: plainToRich(edge.label),
      color: 'black',
    },
    meta: { domain: cleanJson(edge), order },
  };
  const bindings: BindingRecord[] = [
    bindingFor(arrowId, tlShapeId(edge.from), 'start'),
    bindingFor(arrowId, tlShapeId(edge.to), 'end'),
  ];
  return { arrow, bindings };
}

function bindingFor(arrowId: TLShapeId, targetId: TLShapeId, terminal: 'start' | 'end'): BindingRecord {
  return {
    id: createBindingId(),
    type: 'arrow',
    fromId: arrowId,
    toId: targetId,
    props: {
      terminal,
      normalizedAnchor: { x: 0.5, y: 0.5 },
      isExact: false,
      isPrecise: false,
    },
  };
}

/** Hela dokumentet → records (former + pilar + bindningar). */
export function docToRecords(doc: CanvasDoc): {
  shapes: GeoRecord[];
  arrows: ArrowRecord[];
  bindings: BindingRecord[];
} {
  const centers = new Map(doc.shapes.map((s) => [s.id, s.position] as const));
  const shapes = doc.shapes.map((s, i) => shapeToRecord(s, i));
  const arrows: ArrowRecord[] = [];
  const bindings: BindingRecord[] = [];
  doc.edges.forEach((e, i) => {
    const r = edgeToRecords(e, i, (id) => centers.get(id));
    arrows.push(r.arrow);
    bindings.push(...r.bindings);
  });
  return { shapes, arrows, bindings };
}

// ---- Läsriktningen: records → domän (jämför-före-skriv) ----

const EPS = 1e-6;
const near = (a: number, b: number) => Math.abs(a - b) < EPS;

export function recordToShape(rec: GeoRecord, mintId: () => string): ShapeNode {
  const prior = rec.meta?.domain as ShapeNode | undefined;
  const base: ShapeNode = prior
    ? cleanJson(prior)
    : makeShape({
        id: mintId(),
        type: typeForGeo(rec.props.geo),
        position: { x: 0, y: 0 },
        category: 'ui',
      });
  const expected = shapeToRecord(base, 0);

  if (!near(rec.x, expected.x) || !near(rec.y, expected.y) ||
      !near(rec.props.w, expected.props.w) || !near(rec.props.h, expected.props.h)) {
    base.position = { x: rec.x + rec.props.w / 2, y: rec.y + rec.props.h / 2 };
  }
  if (!near(rec.props.w, expected.props.w) || !near(rec.props.h, expected.props.h)) {
    const bs = BASE_SIZES[base.type];
    const wm = rec.props.w / bs.w;
    const hm = rec.props.h / bs.h;
    if (near(wm, hm)) {
      base.sizeMultiplier = wm;
      delete base.widthMultiplier;
      delete base.heightMultiplier;
    } else {
      base.widthMultiplier = wm;
      base.heightMultiplier = hm;
    }
  }
  if (!near(rec.rotation, expected.rotation)) {
    base.rotation = rec.rotation / DEG_TO_RAD;
  }
  const actualText = richToPlain(rec.props.richText);
  const expectedText = base.showLabel ? base.label : '';
  if (actualText !== expectedText) {
    base.label = actualText;
    if (!base.showLabel && actualText !== '') base.showLabel = true;
  }
  return base;
}

export interface ArrowReading {
  arrow: ArrowRecord;
  /** tldraw-RECORD-id för formen pilens start/slut är bunden till (via bindningar). */
  startRecordId?: string;
  endRecordId?: string;
}

function readEdge(
  arrow: ArrowRecord,
  startTarget: string,
  endTarget: string,
  mintId: () => string,
): EdgeConnection {
  const prior = arrow.meta?.domain as EdgeConnection | undefined;
  const base: EdgeConnection = prior
    ? cleanJson(prior)
    : makeEdge({ id: mintId(), from: startTarget, to: endTarget });
  base.from = startTarget;
  base.to = endTarget;

  const expectedHeads = headsFor(base.direction);
  if (arrow.props.arrowheadStart !== expectedHeads.start || arrow.props.arrowheadEnd !== expectedHeads.end) {
    base.direction = directionForHeads(arrow.props.arrowheadStart, arrow.props.arrowheadEnd);
  }
  const expectedDash = base.style === 'dashed' ? 'dashed' : 'solid';
  if (arrow.props.dash !== expectedDash) {
    base.style = arrow.props.dash === 'dashed' ? 'dashed' : 'solid';
  }
  const actualText = richToPlain(arrow.props.richText);
  if (actualText !== base.label) base.label = actualText;
  return base;
}

export interface ReadResult {
  doc: CanvasDoc;
  /** Ärliga varningar (t.ex. pil utan kopplade ändar → tas inte med i filen). */
  warnings: string[];
  /** tldraw-record-id → resulterande nod/kant (för meta-normalisering i editor-limmet). */
  nodeByRecordId: Map<string, ShapeNode>;
  edgeByRecordId: Map<string, EdgeConnection>;
}

/** Records (från editorn) → domändokument. Ordning: meta.order, nya sist i lästordning. */
export function recordsToDoc(
  geoRecords: GeoRecord[],
  arrowReadings: ArrowReading[],
  mintId: () => string = () => crypto.randomUUID().toUpperCase(),
): ReadResult {
  const warnings: string[] = [];
  const byOrder = <T>(list: T[], metaOf: (t: T) => Meta): T[] =>
    list
      .map((r, i) => {
        const order = metaOf(r)?.order;
        return { r, key: typeof order === 'number' ? order : 1_000_000 + i };
      })
      .sort((a, b) => a.key - b.key)
      .map((x) => x.r);

  const nodeByRecordId = new Map<string, ShapeNode>();
  const shapes = byOrder(geoRecords, (g) => g.meta).map((rec) => {
    const node = recordToShape(rec, mintId);
    nodeByRecordId.set(rec.id, node);
    return node;
  });

  const edgeByRecordId = new Map<string, EdgeConnection>();
  const edges: EdgeConnection[] = [];
  for (const reading of byOrder(arrowReadings, (a) => a.arrow.meta)) {
    const startNode = reading.startRecordId ? nodeByRecordId.get(reading.startRecordId) : undefined;
    const endNode = reading.endRecordId ? nodeByRecordId.get(reading.endRecordId) : undefined;
    if (!startNode || !endNode) {
      warnings.push('En pil är inte kopplad mellan två former och sparas inte — koppla båda ändarna eller ta bort den.');
      continue;
    }
    const edge = readEdge(reading.arrow, startNode.id, endNode.id, mintId);
    edgeByRecordId.set(reading.arrow.id, edge);
    edges.push(edge);
  }
  return { doc: { shapes, edges }, warnings, nodeByRecordId, edgeByRecordId };
}
