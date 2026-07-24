// Toolbar-handlingar: ny form + färgpaket + textstil på markering.
// Speglar native CanvasModel+Shapes (defaults per typ) och ToolbarView+ColorsRow
// (applyColorPack rör BARA colorPackId — egna färger vinner fortfarande).
import { makeShape, type ShapeCategory, type ShapeNode, type ShapeType, type TextAlignMode, type TextStyle } from '@v2e/domain';
import type { Editor, TLShapeId } from 'tldraw';
import { shapeToRecord } from '../mapping.js';
import { PICKER_PACKS, packById } from './colors.js';
import { V2E_SHAPE_TYPE } from './shape-props.js';
import type { V2eShape } from './V2eShapeUtil.js';

function mintId(): string {
  return crypto.randomUUID().toUpperCase();
}

function selectedV2e(editor: Editor): V2eShape[] {
  return editor.getSelectedShapes().filter((s): s is V2eShape => s.type === V2E_SHAPE_TYPE);
}

/** Nästa lediga länknummer (native addJumpLinkPair-mönstret). */
function nextLinkNumber(editor: Editor): number {
  const used = new Set<number>();
  for (const s of editor.getCurrentPageShapes()) {
    if (s.type === V2E_SHAPE_TYPE) {
      const n = (s as V2eShape).props.linkNumber;
      if (n > 0) used.add(n);
    }
  }
  let next = 1;
  while (used.has(next)) next += 1;
  return next;
}

/** Native-defaults per form-typ (port av CanvasModel+Shapes.swift). */
function nativeDefaults(editor: Editor, type: ShapeType): Partial<ShapeNode> {
  switch (type) {
    case 'container': return { label: 'Grupp' };
    case 'table': return { sizeMultiplier: 1.5, tableRows: 3, tableCols: 3 };
    case 'link': return { linkNumber: nextLinkNumber(editor) };
    case 'line': return { showLabel: false, lineEnd: { x: 60, y: 0 } };
    case 'arrow': return { showLabel: false, lineEnd: { x: 60, y: 0 } };
    case 'emoji': return { label: '🙂' };
    default: return {};
  }
}

/**
 * Skapa en ny v2e-form på en EXAKT punkt (page-koordinater) — drag-ut-vägen.
 * Noden byggs som full domän-nod (meta.domain) → round-trippar direkt.
 */
export function addDomainShapeAt(
  editor: Editor,
  type: ShapeType,
  point: { x: number; y: number },
  category: ShapeCategory = 'ui',
): TLShapeId {
  const node = makeShape({
    id: mintId(),
    type,
    position: { x: point.x, y: point.y },
    category,
    ...nativeDefaults(editor, type),
  });
  const rec = shapeToRecord(node, 0);
  // Ingen meta.order → sorteras EFTER alla sparade former vid läsning (nya sist).
  const record = { ...rec, meta: { domain: rec.meta.domain } };
  editor.run(() => {
    editor.createShapes([record as never]);
    editor.setSelectedShapes([record.id]);
  });
  return record.id;
}

/** Skapa en ny v2e-form i viewport-mitten (tryck-vägen), med kaskad-förskjutning. */
export function addDomainShape(
  editor: Editor,
  type: ShapeType,
  category: ShapeCategory = 'ui',
): TLShapeId {
  const center = editor.getViewportPageBounds().center;
  // Kaskad-förskjutning: nya former hamnar inte på EXAKT samma punkt (SIM-KOLL-fynd 2026-07-09).
  const existing = editor.getCurrentPageShapes().filter((s) => s.type === V2E_SHAPE_TYPE).length;
  const off = (existing % 8) * 28;
  return addDomainShapeAt(editor, type, { x: center.x + off, y: center.y + off }, category);
}

/**
 * Applicera färgpaket på markerade v2e-former. `pack` = webbens picker-nummer 0–7
 * (PICKER_PACKS-ordning) eller ett pack-id ('blå', 'ui-mörk', …). Som native:
 * BARA colorPackId ändras ('none' → inget paket).
 */
export function applyColorPack(editor: Editor, pack: number | string): void {
  const id = typeof pack === 'number' ? (PICKER_PACKS[pack]?.id ?? 'none') : packById(pack).id;
  const value = id === 'none' ? '' : id;
  const updates = selectedV2e(editor).map((s) => ({
    id: s.id,
    type: V2E_SHAPE_TYPE,
    props: { colorPackId: value },
  }));
  if (updates.length > 0) editor.updateShapes(updates);
}

/**
 * Egen fyllnings-/ramfärg på markerade former. Hex '#rrggbb' sätter, '' rensar.
 * Vinner över färgpaket (native: egna färger prioriteras). Round-trippar via `%% color`/`%% stroke`.
 */
export function applyCustomColor(
  editor: Editor,
  patch: { color?: string; strokeColor?: string },
): void {
  const props: Record<string, string> = {};
  if (patch.color !== undefined) props.color = patch.color;
  if (patch.strokeColor !== undefined) props.strokeColor = patch.strokeColor;
  if (Object.keys(props).length === 0) return;
  const updates = selectedV2e(editor).map((s) => ({ id: s.id, type: V2E_SHAPE_TYPE, props }));
  if (updates.length > 0) editor.updateShapes(updates);
}

export interface TextStylePatch {
  textStyle?: TextStyle;
  bold?: boolean;
  italic?: boolean;
  underline?: boolean;
  textAlignment?: TextAlignMode;
  hasBullets?: boolean;
  hasNumberedList?: boolean;
  indentLevel?: number;
}

/** Applicera textstil på markerade v2e-former. Punkt/nummer utesluter varandra (som native). */
export function applyTextStyle(editor: Editor, patch: TextStylePatch): void {
  const updates = selectedV2e(editor).map((s) => {
    const props: TextStylePatch = { ...patch };
    if (patch.hasBullets) props.hasNumberedList = false;
    if (patch.hasNumberedList) props.hasBullets = false;
    if (patch.indentLevel !== undefined) {
      props.indentLevel = Math.min(3, Math.max(0, patch.indentLevel));
    }
    return { id: s.id, type: V2E_SHAPE_TYPE, props };
  });
  if (updates.length > 0) editor.updateShapes(updates);
}
