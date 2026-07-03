// Färger — EXAKT port av Swift ShapeCategory (fill/stroke/text), ColorPack.swift
// och ShapeView+Style.swift (precedens). REN modul (ingen React) — Node-testbar.
import type { ShapeCategory } from '@v2e/domain';

export interface ColorSet {
  fill: string;
  stroke: string;
  text: string;
}

/** Port av ShapeCategory.fillColor / strokeColor / textColor — alla kategorier, kompilerings-tvingad täckning. */
export const CATEGORY_COLORS = {
  // UI
  ui:        { fill: '#1d4ed8', stroke: '#1e293b', text: '#f9fafb' },
  zone:      { fill: '#e5e7eb', stroke: '#9ca3af', text: '#111827' },
  note:      { fill: '#ecfdf3', stroke: '#16a34a', text: '#166534' },
  overlay:   { fill: '#0f172a', stroke: '#38bdf8', text: '#f9fafb' },
  // Roadmap
  feat:      { fill: '#2563eb', stroke: '#1e40af', text: '#f9fafb' },
  milestone: { fill: '#f59e0b', stroke: '#b45309', text: '#f9fafb' },
  blocker:   { fill: '#dc2626', stroke: '#991b1b', text: '#f9fafb' },
  future:    { fill: '#a78bfa', stroke: '#7c3aed', text: '#f9fafb' },
  // Arkitektur
  folder:    { fill: '#f3f4f6', stroke: '#9ca3af', text: '#111827' },
  file:      { fill: '#fafafa', stroke: '#d1d5db', text: '#111827' },
  module:    { fill: '#0ea5e9', stroke: '#0369a1', text: '#f9fafb' },
  service:   { fill: '#14b8a6', stroke: '#0f766e', text: '#f9fafb' },
  data:      { fill: '#84cc16', stroke: '#4d7c0f', text: '#f9fafb' },
  // Flow
  input:     { fill: '#22c55e', stroke: '#15803d', text: '#f9fafb' },
  agent:     { fill: '#6366f1', stroke: '#4338ca', text: '#f9fafb' },
  tool:      { fill: '#fb923c', stroke: '#c2410c', text: '#f9fafb' },
  router:    { fill: '#eab308', stroke: '#a16207', text: '#f9fafb' },
  memory:    { fill: '#8b5cf6', stroke: '#6d28d9', text: '#f9fafb' },
  output:    { fill: '#ef4444', stroke: '#b91c1c', text: '#f9fafb' },
  // v31 Prompt-Process
  subagent:  { fill: '#7c3aed', stroke: '#5b21b6', text: '#f9fafb' },
  prompt:    { fill: '#10b981', stroke: '#059669', text: '#f9fafb' },
  skill:     { fill: '#f97316', stroke: '#c2410c', text: '#f9fafb' },
  // v69 process-kontroll
  gate:      { fill: '#e11d48', stroke: '#9f1239', text: '#f9fafb' },
  evidence:  { fill: '#64748b', stroke: '#334155', text: '#f9fafb' },
  manual:    { fill: '#dc2626', stroke: '#7f1d1d', text: '#f9fafb' },
  script:    { fill: '#06b6d4', stroke: '#0e7490', text: '#f9fafb' },
  // steg 8 skill-flöde
  mcp:          { fill: '#0d9488', stroke: '#0f766e', text: '#f9fafb' },
  plugin:       { fill: '#db2777', stroke: '#9d174d', text: '#f9fafb' },
  fileMarkdown: { fill: '#f8fafc', stroke: '#64748b', text: '#111827' },
  fileExcel:    { fill: '#f0fdf4', stroke: '#15803d', text: '#111827' },
  // Godot
  godot_scene:     { fill: '#478cbf', stroke: '#215378', text: '#f9fafb' },
  godot_control:   { fill: '#6b7280', stroke: '#374151', text: '#f9fafb' },
  godot_container: { fill: '#a479d3', stroke: '#7c3aed', text: '#f9fafb' },
  godot_panel:     { fill: '#e9ecef', stroke: '#adb5bd', text: '#111827' },
  godot_button:    { fill: '#ffa94d', stroke: '#ea580c', text: '#111827' },
  godot_label:     { fill: '#f1f3f5', stroke: '#d1d5db', text: '#111827' },
  godot_signal:    { fill: '#fcd34d', stroke: '#ca8a04', text: '#111827' },
  godot_script:    { fill: '#4ade80', stroke: '#16a34a', text: '#064e3b' },
} as const satisfies Record<ShapeCategory, ColorSet>;

export interface ColorPack extends ColorSet {
  id: string;
  name: string;
}

/** Port av ColorPack.all — ALLA 12 paket finns kvar så gamla filer behåller sin färg. */
export const COLOR_PACKS: readonly ColorPack[] = [
  { id: 'none',    name: 'Ingen färg',       fill: '#ffffff', stroke: '#6b7280', text: '#111827' },
  { id: 'persika', name: 'Persika',          fill: '#ffe6d6', stroke: '#efa379', text: '#7e4226' },
  { id: 'rosa',    name: 'Rosa',             fill: '#ffe1ea', stroke: '#f291a8', text: '#883350' },
  { id: 'blå',     name: 'Blå',              fill: '#deedfd', stroke: '#74b0e6', text: '#18497e' },
  { id: 'grön',    name: 'Grön',             fill: '#daf0e0', stroke: '#74c09a', text: '#205a3c' },
  { id: 'gul',     name: 'Gul',              fill: '#fff0cd', stroke: '#e4b854', text: '#6c4b16' },
  { id: 'lila',    name: 'Lila',             fill: '#ebdcfb', stroke: '#ad92dd', text: '#46296f' },
  { id: 'ui-blå',  name: 'UI Blå (knapp)',   fill: '#0a84ff', stroke: '#0a6cd8', text: '#ffffff' },
  { id: 'ui-grön', name: 'UI Grön',          fill: '#34c759', stroke: '#28a745', text: '#ffffff' },
  { id: 'ui-röd',  name: 'UI Röd',           fill: '#ff3b30', stroke: '#d70015', text: '#ffffff' },
  { id: 'ui-grå',  name: 'UI Grå (yta)',     fill: '#f2f2f7', stroke: '#c7c7cc', text: '#1c1c1e' },
  { id: 'ui-mörk', name: 'UI Mörk (navbar)', fill: '#1c1c1e', stroke: '#3a3a3c', text: '#ffffff' },
];

/** Port av ColorPack.pickerVisible — de 8 som visas, i picker-ordning (index = webbens pack-nummer 0–7). */
export const PICKER_PACK_IDS = ['none', 'blå', 'grön', 'gul', 'rosa', 'lila', 'persika', 'ui-blå'] as const;

export const PICKER_PACKS: readonly ColorPack[] = PICKER_PACK_IDS.map(
  (id) => COLOR_PACKS.find((p) => p.id === id)!,
);

/** Port av ColorPack.by(id:) — okänt/'' → none. */
export function packById(id: string | undefined): ColorPack {
  if (!id) return COLOR_PACKS[0]!;
  return COLOR_PACKS.find((p) => p.id === id) ?? COLOR_PACKS[0]!;
}

/** Port av Color(hexString:) giltighetskravet — exakt 6 hex-tecken efter '#'. */
export function isValidHex(hex: string | undefined): hex is string {
  if (!hex) return false;
  return /^[0-9a-fA-F]{6}$/.test(hex.trim().replace(/#/g, ''));
}

/** Port av Color.isDarkHex (YIQ-luminans) — styr svart/vit text på egen fyllning. */
export function isDarkHex(hex: string): boolean {
  const raw = hex.trim().replace(/#/g, '');
  if (!/^[0-9a-fA-F]{6}$/.test(raw)) return false;
  const v = parseInt(raw, 16);
  const r = (v >> 16) & 0xff;
  const g = (v >> 8) & 0xff;
  const b = v & 0xff;
  return (r * 299 + g * 587 + b * 114) / 1000 < 128;
}

export interface StyleInput {
  category: ShapeCategory;
  /** ''/undefined = inget paket (none). */
  colorPackId?: string;
  /** ''/undefined = ingen egen fyllning. */
  color?: string;
  /** ''/undefined = ingen egen ram. */
  strokeColor?: string;
}

/**
 * Port av ShapeView+Style effectiveFill/effectiveStroke/effectiveTextColor:
 * fyllning: egen färg > paket (none = vit). ram: egen ram > paket (≠none) > kategori-ram.
 * text: egen fyllning → svart/vit på luminans, annars paketets textfärg.
 * OBS (Swift-sanning): kategns FYLLNING används INTE på canvasen — default är vit + kategori-ram.
 */
export function effectiveColors(s: StyleInput): ColorSet {
  const pack = packById(s.colorPackId);
  const fill = isValidHex(s.color) ? normalizeHex(s.color) : pack.fill;
  const stroke = isValidHex(s.strokeColor)
    ? normalizeHex(s.strokeColor)
    : pack.id !== 'none'
      ? pack.stroke
      : CATEGORY_COLORS[s.category].stroke;
  const text = isValidHex(s.color) ? (isDarkHex(s.color) ? '#ffffff' : '#111827') : pack.text;
  return { fill, stroke, text };
}

function normalizeHex(hex: string): string {
  return `#${hex.trim().replace(/#/g, '').toLowerCase()}`;
}
