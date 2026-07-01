// Domän-modell — trogen TS-port av Swift ShapeNode.swift + EdgeConnection.swift + ShapeCategory.swift.
// REN: inga beroenden (ingen React/nät/DOM). CGPoint → {x,y}, CGFloat → number, UUID → string.
// Källor: app/MermaidCanvas/Sources/App/Models/{ShapeNode,EdgeConnection}.swift
//         app/MermaidCanvas/Sources/ClaudeCode/ShapeCategory.swift
//         app/MermaidCanvas/Sources/App/Models/TextStyle.swift

export interface Point {
  x: number;
  y: number;
}

/** Trogen port av Swift ShapeType (ShapeNode.swift). Ordning bevarad. */
export const SHAPE_TYPES = [
  'circle', 'rectangle', 'diamond', 'table', 'link', 'pill', 'line', 'arrow',
  'square', 'processArrow', 'container', 'octagon', 'phoneFrame', 'triangle',
  'cylinder', 'emoji',
] as const;
export type ShapeType = (typeof SHAPE_TYPES)[number];

/** Former som ÄGER innehåll (Mermaid subgraph / UI-skärm). */
export const CONTAINER_SHAPE_TYPES: ReadonlySet<ShapeType> = new Set(['container', 'phoneFrame']);

/** Trogen port av Swift ShapeCategory (ShapeCategory.swift). Alla cases, ordning bevarad. */
export const SHAPE_CATEGORIES = [
  // UI
  'ui', 'zone', 'note', 'overlay',
  // Roadmap
  'feat', 'milestone', 'blocker', 'future',
  // Arkitektur
  'folder', 'file', 'module', 'service', 'data',
  // Flow
  'input', 'agent', 'tool', 'router', 'memory', 'output',
  // Skill-flöde
  'subagent', 'prompt', 'skill',
  // Process-kontroll
  'gate', 'evidence', 'manual', 'script',
  // Skill-flöde-vokabulär (steg 8)
  'mcp', 'plugin', 'fileMarkdown', 'fileExcel',
  // Godot
  'godot_scene', 'godot_control', 'godot_container', 'godot_panel',
  'godot_button', 'godot_label', 'godot_signal', 'godot_script',
] as const;
export type ShapeCategory = (typeof SHAPE_CATEGORIES)[number];

/** Trogen port av Swift TextStyle (TextStyle.swift). */
export const TEXT_STYLES = ['jatte', 'r1', 'r2', 'r3', 'body'] as const;
export type TextStyle = (typeof TEXT_STYLES)[number];

/** v37 textjustering. */
export type TextAlignMode = 'leading' | 'center' | 'trailing';

// ---- Edge-enums (EdgeConnection.swift) ----
export type EdgeStyle = 'solid' | 'dashed';
export type EdgeDirection = 'forward' | 'backward' | 'bidirectional' | 'none';
export type EdgeLabelPlacement = 'above' | 'below';
export type EdgeSide = 'top' | 'right' | 'bottom' | 'left';
export type EdgeLineShape = 'straight' | 'curved' | 'orthogonal';

export interface EdgeWaypoint {
  x: number;
  y: number;
}

/**
 * Trogen port av Swift ShapeNode. Optionella Swift-fält (`?`) = valfria TS-fält.
 * OBS: SubCanvas (v1.0+ Visio "hoppa in") är PARKERAD i native (bröt noll-avvikelse) — modelleras
 * som ogenomskinlig `unknown` tills/om den återupptas; rör inte utan spec.
 */
export interface ShapeNode {
  id: string;
  type: ShapeType;
  position: Point;
  label: string;
  showLabel: boolean;
  sizeMultiplier: number;
  widthMultiplier?: number;
  heightMultiplier?: number;
  note: string;
  prompt: string;
  category: ShapeCategory;
  rotation: number;
  colorOverride?: string;
  strokeColorOverride?: string;
  linkNumber?: number;
  skillNumber?: number;
  tableRows?: number;
  tableCols?: number;
  tableCells?: string[][];
  textStyle: TextStyle;
  colorPackId?: string;
  lineEnd?: Point;
  textAlignment: TextAlignMode;
  hasBullets: boolean;
  hasNumberedList: boolean;
  indentLevel: number;
  bold: boolean;
  italic: boolean;
  underline: boolean;
  childOfContainerId?: string;
  locked: boolean;
  zLayer: number;
  subCanvas?: unknown;
}

/** Trogen port av Swift EdgeConnection. */
export interface EdgeConnection {
  id: string;
  from: string;
  to: string;
  label: string;
  direction: EdgeDirection;
  style: EdgeStyle;
  waypoints: EdgeWaypoint[];
  labelPlacement: EdgeLabelPlacement;
  colorHex?: string;
  fromSide?: EdgeSide;
  toSide?: EdgeSide;
  lineShape: EdgeLineShape;
}

/** Hela canvas-dokumentet (motsvarar CanvasModel:s shapes + edges). */
export interface CanvasDoc {
  shapes: ShapeNode[];
  edges: EdgeConnection[];
}

// ---- Fabriker med Swift-trogna default-värden (speglar Swift `init(...)`-defaults) ----

export type ShapeInit = Partial<ShapeNode> & Pick<ShapeNode, 'id' | 'type' | 'position'>;

export function makeShape(init: ShapeInit): ShapeNode {
  return {
    showLabel: true,
    label: '',
    sizeMultiplier: 1,
    note: '',
    prompt: '',
    category: 'ui',
    rotation: 0,
    textStyle: 'body',
    textAlignment: 'center',
    hasBullets: false,
    hasNumberedList: false,
    indentLevel: 0,
    bold: false,
    italic: false,
    underline: false,
    locked: false,
    zLayer: 0,
    ...init,
  };
}

export type EdgeInit = Partial<EdgeConnection> & Pick<EdgeConnection, 'id' | 'from' | 'to'>;

export function makeEdge(init: EdgeInit): EdgeConnection {
  return {
    label: '',
    direction: 'forward',
    style: 'solid',
    waypoints: [],
    labelPlacement: 'below',
    lineShape: 'curved',
    ...init,
  };
}
