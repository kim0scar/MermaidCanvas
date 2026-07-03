// Port av Swift MermaidMetaComments.swift + MermaidParser+EdgeMeta.swift —
// läser `%%`-metadata ur mermaid-kroppen (Tier 2-fallback utan state-JSON).
// Speglar Swifts tolkning EXAKT (samma nycklar, samma tolerans, samma tystnad
// vid okända nycklar). REN TS, 0 beroenden.

import type {
  EdgeLabelPlacement,
  EdgeLineShape,
  EdgeSide,
  EdgeWaypoint,
  Point,
} from './model.js';

/** Metadata per nod-id ur `%% <id> nyckel[: värde]`-rader (Swift NodeMeta). */
export interface NodeMeta {
  position?: Point;
  size?: number;
  rotation?: number;
  width?: number;
  height?: number;
  color?: string;
  stroke?: string;
  note?: string;
  prompt?: string;
  textStyleRaw?: string;
  packId?: string;
  hiddenLabel: boolean;
  collapsed: boolean;
  link?: number;
  skillNumber?: number;
  tableRows?: number;
  tableCols?: number;
  tableCells?: string[][];
  /** Label från `%% name:` — återställer text när nod-kroppen visar " " (dold etikett). */
  name?: string;
  /** Absolut slutpunkt för lösa linjer/pilar (generatorn skriver absolut). */
  lineEndAbsolute?: Point;
  shapeTypeRaw?: string;
  textAlignRaw?: string;
  hasBullets: boolean;
  hasNumberedList: boolean;
  indentLevel: number;
  locked: boolean;
  zLayer: number;
}

function emptyMeta(): NodeMeta {
  return {
    hiddenLabel: false, collapsed: false,
    hasBullets: false, hasNumberedList: false,
    indentLevel: 0, locked: false, zLayer: 0,
  };
}

/** Omvänd MermaidGenerator.oneLine — " ⏎ " → radbrytning, "%-%" → "%%". */
export function multiLine(text: string): string {
  return text.split(' ⏎ ').join('\n').split('%-%').join('%%');
}

/** Swift Double(...)-semantik: trimmad icke-tom sträng → ändligt tal. */
function parseDouble(raw: string): number | undefined {
  const t = raw.trim();
  if (t === '') return undefined;
  const d = Number(t);
  return Number.isFinite(d) ? d : undefined;
}

/** Swift Int(...)-semantik: bara hela tal. */
function parseIntStrict(raw: string): number | undefined {
  return /^[+-]?\d+$/.test(raw) ? parseInt(raw, 10) : undefined;
}

/** "123,456" → Point. Tål negativa värden. (Swift split hoppar tomma delar.) */
function parsePoint(value: string): Point | undefined {
  const parts = value.split(',').filter((p) => p.length > 0);
  if (parts.length !== 2) return undefined;
  const x = parseDouble(parts[0]!);
  const y = parseDouble(parts[1]!);
  if (x === undefined || y === undefined) return undefined;
  return { x, y };
}

/** JSON `[["a","b"],...]` → tabellceller (Swift `obj as? [[String]]`). */
function parseCells(value: string): string[][] | undefined {
  try {
    const obj: unknown = JSON.parse(value);
    if (Array.isArray(obj) && obj.every((r) => Array.isArray(r) && r.every((c) => typeof c === 'string'))) {
      return obj as string[][];
    }
  } catch { /* trasig JSON → ignorera, som Swift */ }
  return undefined;
}

/** Skannar mermaid-blocket rad för rad → metadata per mermaid-id (Swift parse). */
export function parseNodeMeta(block: string): Map<string, NodeMeta> {
  const result = new Map<string, NodeMeta>();
  for (const rawLine of block.split('\n')) {
    const line = rawLine.trim();
    if (line === '' || !line.startsWith('%%') || line.startsWith('%%{')) continue;
    // Format: "%% <id> <nyckel>[: <värde>]"
    const body = line.slice(2).trim();
    const firstSpace = body.indexOf(' ');
    if (firstSpace === -1) continue;
    const id = body.slice(0, firstSpace);
    const rest = body.slice(firstSpace + 1).trim();
    if (id === '' || rest === '') continue;
    const meta = result.get(id) ?? emptyMeta();
    applyMeta(rest, meta);
    result.set(id, meta);
  }
  return result;
}

function applyMeta(rest: string, meta: NodeMeta): void {
  // Flagg-nycklar utan värde
  if (rest === 'hidden-label') { meta.hiddenLabel = true; return; }
  if (rest === 'collapsed') { meta.collapsed = true; return; }
  if (rest === 'bullets') { meta.hasBullets = true; return; }
  if (rest === 'numbered') { meta.hasNumberedList = true; return; }
  if (rest === 'locked') { meta.locked = true; return; }

  const colon = rest.indexOf(':');
  if (colon === -1) return;
  const key = rest.slice(0, colon).trim();
  const value = rest.slice(colon + 1).trim();
  if (value === '') return;

  switch (key) {
    case 'pos': case 'container-pos': {
      const p = parsePoint(value);
      if (p) meta.position = p;
      break;
    }
    case 'size': {
      const d = parseDouble(value);
      if (d !== undefined) meta.size = d;
      break;
    }
    case 'rot': {
      // Skrivs som "45°" — strippa gradtecknet
      const d = parseDouble(value.split('°').join(''));
      if (d !== undefined) meta.rotation = d;
      break;
    }
    case 'width': {
      const d = parseDouble(value);
      if (d !== undefined) meta.width = d;
      break;
    }
    case 'height': {
      const d = parseDouble(value);
      if (d !== undefined) meta.height = d;
      break;
    }
    case 'color': meta.color = value; break;
    case 'stroke': meta.stroke = value; break;
    case 'note': meta.note = multiLine(value); break;
    case 'prompt': meta.prompt = multiLine(value); break;
    case 'style': meta.textStyleRaw = value; break;
    case 'pack': meta.packId = value; break;
    case 'name': meta.name = multiLine(value); break;
    case 'link': {
      const i = parseIntStrict(value);
      if (i !== undefined) meta.link = i;
      break;
    }
    case 'skill-nr': {
      const i = parseIntStrict(value);
      if (i !== undefined) meta.skillNumber = i;
      break;
    }
    case 'table': {
      // Skrivs som "3×4"
      const parts = value.split('×').filter((p) => p.length > 0);
      if (parts.length === 2) {
        const r = parseIntStrict(parts[0]!);
        const c = parseIntStrict(parts[1]!);
        if (r !== undefined && c !== undefined) { meta.tableRows = r; meta.tableCols = c; }
      }
      break;
    }
    case 'table-cells': {
      const cells = parseCells(value);
      if (cells) meta.tableCells = cells;
      break;
    }
    case 'line-end': {
      const p = parsePoint(value);
      if (p) meta.lineEndAbsolute = p;
      break;
    }
    case 'shape-type': meta.shapeTypeRaw = value; break;
    case 'align': meta.textAlignRaw = value; break;
    case 'indent': {
      const i = parseIntStrict(value);
      if (i !== undefined) meta.indentLevel = i;
      break;
    }
    case 'z': {
      const i = parseIntStrict(value);
      if (i !== undefined) meta.zLayer = i;
      break;
    }
    default: break; // okänd nyckel — ignorera (som Swift)
  }
}

// ---- Kant-metadata: `%% e<index> nyckel: värde` (Swift EdgeMeta) ----

export interface EdgeMeta {
  placements: Map<number, EdgeLabelPlacement>;
  colors: Map<number, string>;
  fromSides: Map<number, EdgeSide>;
  toSides: Map<number, EdgeSide>;
  waypoints: Map<number, EdgeWaypoint[]>;
  lineShapes: Map<number, EdgeLineShape>;
  collapsedIndices: Set<number>;
}

const PLACEMENTS: readonly EdgeLabelPlacement[] = ['above', 'below'];
const SIDES: readonly EdgeSide[] = ['top', 'right', 'bottom', 'left'];
const LINE_SHAPES: readonly EdgeLineShape[] = ['straight', 'curved', 'orthogonal'];

function oneOf<T extends string>(v: string, allowed: readonly T[]): T | undefined {
  return (allowed as readonly string[]).includes(v) ? (v as T) : undefined;
}

/** Parsar `%% e<index> nyckel: värde`-kant-kommentarerna ur blocket (Swift parseEdgeMeta). */
export function parseEdgeMeta(block: string): EdgeMeta {
  const meta: EdgeMeta = {
    placements: new Map(), colors: new Map(), fromSides: new Map(),
    toSides: new Map(), waypoints: new Map(), lineShapes: new Map(),
    collapsedIndices: new Set(),
  };
  for (const m of block.matchAll(/%%\s+e(\d+)\s+(\w+):\s+(\S+)/g)) {
    const idx = parseInt(m[1]!, 10);
    const key = m[2]!;
    const value = m[3]!;
    switch (key) {
      case 'labelPlacement': {
        const p = oneOf(value, PLACEMENTS);
        if (p) meta.placements.set(idx, p);
        break;
      }
      case 'color': meta.colors.set(idx, value); break;
      case 'fromSide': {
        const s = oneOf(value, SIDES);
        if (s) meta.fromSides.set(idx, s);
        break;
      }
      case 'toSide': {
        const s = oneOf(value, SIDES);
        if (s) meta.toSides.set(idx, s);
        break;
      }
      case 'lineShape': {
        const ls = oneOf(value, LINE_SHAPES);
        if (ls) meta.lineShapes.set(idx, ls);
        break;
      }
      case 'collapsed':
        if (value === 'true') meta.collapsedIndices.add(idx);
        break;
      case 'waypoint': {
        // Flera "%% e<i> waypoint: x,y"-rader per kant — ackumuleras i ordning.
        const parts = value.split(',').filter((p) => p.length > 0);
        if (parts.length === 2) {
          const wx = parseDouble(parts[0]!);
          const wy = parseDouble(parts[1]!);
          if (wx !== undefined && wy !== undefined) {
            const list = meta.waypoints.get(idx) ?? [];
            list.push({ x: wx, y: wy });
            meta.waypoints.set(idx, list);
          }
        }
        break;
      }
      default: break;
    }
  }
  return meta;
}
