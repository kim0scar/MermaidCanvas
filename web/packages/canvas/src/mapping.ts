// Domän ↔ tldraw-records — REN datamappning (ingen Editor, Node-testbar).
//
// Princip (noll-avvikelse): tldraw är bara REDIGERINGS-modellen; domänen är sanning.
// Varje record bär sin domän-nod i `meta.domain` (= senast sparade läget). Vid läsning
// jämförs tldraw-värdena mot det FÖRVÄNTADE (beräknat ur meta.domain) — bara det som
// faktiskt ändrats skrivs tillbaka i modellen. Orörda fält förblir byte-exakta.
//
// Sedan v2e-shape: domän-noder är CUSTOM-formen 'v2e-shape' (native-trogen rendering);
// stil-fälten bor i props (validerade), resten av noden i meta.domain som förut.
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
import { V2E_SHAPE_TYPE, type V2eShapeProps } from './native/shape-props.js';

/** Närmaste tldraw-geo per form-typ (kvar för bakåtkomp/glyfer; renderingen är nu v2e-shape). */
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

/** Form-typ för geo-verktygens former (bakåtkomp — nya former skapas via addDomainShape). */
export function typeForGeo(geo: string): ShapeType {
  if (geo === 'ellipse') return 'circle';
  if (geo === 'diamond') return 'diamond';
  return 'rectangle';
}

const DEG_TO_RAD = Math.PI / 180;

type Meta = { domain?: unknown; order?: number };

export interface V2eRecord {
  id: TLShapeId;
  type: typeof V2E_SHAPE_TYPE;
  x: number;
  y: number;
  rotation: number;
  props: V2eShapeProps;
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

export function shapeToRecord(node: ShapeNode, order: number): V2eRecord {
  const { w, h } = effectiveSize(node);
  return {
    id: tlShapeId(node.id),
    type: V2E_SHAPE_TYPE,
    x: node.position.x - w / 2,
    y: node.position.y - h / 2,
    rotation: node.rotation * DEG_TO_RAD,
    props: {
      w,
      h,
      shapeType: node.type,
      category: node.category,
      // Etiketten reser ALLTID i richText (även dold) — synligheten styrs av showLabel.
      richText: plainToRich(node.label),
      showLabel: node.showLabel,
      sizeMultiplier: node.sizeMultiplier,
      textStyle: node.textStyle,
      bold: node.bold,
      italic: node.italic,
      underline: node.underline,
      textAlignment: node.textAlignment,
      hasBullets: node.hasBullets,
      hasNumberedList: node.hasNumberedList,
      indentLevel: node.indentLevel,
      colorPackId: node.colorPackId ?? '',
      color: node.colorOverride ?? '',
      strokeColor: node.strokeColorOverride ?? '',
      tableRows: node.tableRows ?? 0,
      tableCols: node.tableCols ?? 0,
      tableCells: node.tableCells ? cleanJson(node.tableCells) : [],
      linkNumber: node.linkNumber ?? 0,
      skillNumber: node.skillNumber ?? 0,
      isSubskill: node.childOfContainerId !== undefined,
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
  shapes: V2eRecord[];
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

/** Sätt eller ta bort ett valfritt domän-fält utifrån props-sentinel ('' / 0 / []). */
function setOrDelete<K extends keyof ShapeNode>(base: ShapeNode, key: K, value: ShapeNode[K] | undefined): void {
  if (value === undefined) delete base[key];
  else base[key] = value;
}

export function recordToShape(rec: V2eRecord, mintId: () => string): ShapeNode {
  const prior = rec.meta?.domain as ShapeNode | undefined;
  const base: ShapeNode = prior
    ? cleanJson(prior)
    : makeShape({
        id: mintId(),
        type: rec.props.shapeType,
        position: { x: 0, y: 0 },
        category: rec.props.category,
      });
  // Typ/kategori först — storleks-härledningen nedan läser BASE_SIZES[base.type].
  const expected = shapeToRecord(base, 0);
  const p = rec.props;
  const xp = expected.props;
  if (p.shapeType !== xp.shapeType) base.type = p.shapeType;
  if (p.category !== xp.category) base.category = p.category;

  if (!near(rec.x, expected.x) || !near(rec.y, expected.y) ||
      !near(p.w, xp.w) || !near(p.h, xp.h)) {
    base.position = { x: rec.x + p.w / 2, y: rec.y + p.h / 2 };
  }
  if (!near(p.w, xp.w) || !near(p.h, xp.h)) {
    const bs = BASE_SIZES[base.type];
    const wm = p.w / bs.w;
    const hm = p.h / bs.h;
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
  const actualText = richToPlain(p.richText);
  if (actualText !== base.label) {
    base.label = actualText;
    if (!base.showLabel && actualText !== '') base.showLabel = true;
  }

  // Stil-fälten (bara faktiskt ändrade props skrivs — orörd nod förblir byte-identisk).
  if (p.showLabel !== xp.showLabel) base.showLabel = p.showLabel;
  if (p.textStyle !== xp.textStyle) base.textStyle = p.textStyle;
  if (p.textAlignment !== xp.textAlignment) base.textAlignment = p.textAlignment;
  if (p.bold !== xp.bold) base.bold = p.bold;
  if (p.italic !== xp.italic) base.italic = p.italic;
  if (p.underline !== xp.underline) base.underline = p.underline;
  if (p.hasBullets !== xp.hasBullets) base.hasBullets = p.hasBullets;
  if (p.hasNumberedList !== xp.hasNumberedList) base.hasNumberedList = p.hasNumberedList;
  if (p.indentLevel !== xp.indentLevel) base.indentLevel = p.indentLevel;
  if (p.colorPackId !== xp.colorPackId) setOrDelete(base, 'colorPackId', p.colorPackId || undefined);
  if (p.color !== xp.color) setOrDelete(base, 'colorOverride', p.color || undefined);
  if (p.strokeColor !== xp.strokeColor) setOrDelete(base, 'strokeColorOverride', p.strokeColor || undefined);
  if (p.tableRows !== xp.tableRows) setOrDelete(base, 'tableRows', p.tableRows || undefined);
  if (p.tableCols !== xp.tableCols) setOrDelete(base, 'tableCols', p.tableCols || undefined);
  if (JSON.stringify(p.tableCells) !== JSON.stringify(xp.tableCells)) {
    setOrDelete(base, 'tableCells', p.tableCells.length > 0 ? cleanJson(p.tableCells) : undefined);
  }
  if (p.linkNumber !== xp.linkNumber) setOrDelete(base, 'linkNumber', p.linkNumber || undefined);
  if (p.skillNumber !== xp.skillNumber) setOrDelete(base, 'skillNumber', p.skillNumber || undefined);
  // OBS: props.sizeMultiplier är en render-hint (fontskala) — w/h är sanningen, läses ej tillbaka.
  // OBS: props.isSubskill är härledd ur childOfContainerId — läses ej tillbaka.
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
  v2eRecords: V2eRecord[],
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
  const shapes = byOrder(v2eRecords, (g) => g.meta).map((rec) => {
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
