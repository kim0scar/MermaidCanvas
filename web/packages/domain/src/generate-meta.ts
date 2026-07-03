// %%-metadata-emissionen för Tier 2-kroppen — trogen port av Swift MermaidGenerator.swift
// (nod- + container-loopen), MermaidGenerator+Edges.swift samt encodeCells ur MermaidMetaComments.
// Villkor, format och RADORDNING är exakt Swifts — bara icke-default skrivs.
// Guld-orakel mot riktig Swift-output i test/generate-golden.test.ts.

import type { EdgeConnection, ShapeCategory, ShapeNode, ShapeType } from './model.js';
import { SHAPE_CATEGORIES } from './model.js';

/** Swift oneLine — radbrytningar + dubbla procenttecken görs enrads-säkra (omvänds av parsern). */
export function oneLine(text: string): string {
  return text.replace(/\n/g, ' ⏎ ').replace(/%%/g, '%-%');
}

/** Swift `.rounded()` — halvor avrundas IFRÅN noll (JS Math.round drar -0.5 mot 0). */
export function swiftRound(n: number): number {
  return n < 0 ? -Math.round(-n) : Math.round(n);
}

/** Swift encodeCells — kompakt JSON på en rad. JSONSerialization escapar `/` som `\/`. */
export function encodeCells(cells: string[][] | undefined): string | undefined {
  if (!cells) return undefined;
  return JSON.stringify(cells).replace(/\//g, '\\/');
}

/** Typer utan egen mermaid-syntax → identiteten bärs av shape-type-raden (Swift-listan, exakt). */
const SHAPE_TYPE_CARRIED: ReadonlySet<ShapeType> = new Set([
  'phoneFrame', 'triangle', 'table', 'link',
  'square', 'processArrow', 'octagon', 'line', 'arrow', 'emoji',
]);

/** %%-raderna för en NOD (ej container). Ordning = Swift generate()-nodloopen. */
export function nodeMetaLines(s: ShapeNode, id: string, ind: string): string[] {
  const m: string[] = [];
  if (s.note !== '') m.push(`${ind}%% ${id} note: ${oneLine(s.note)}`);
  if (Math.abs(s.sizeMultiplier - 1.0) > 0.01) m.push(`${ind}%% ${id} size: ${s.sizeMultiplier.toFixed(1)}`);
  if (Math.abs(s.rotation) > 0.5) m.push(`${ind}%% ${id} rot: ${swiftRound(s.rotation)}°`);
  if (!s.showLabel) m.push(`${ind}%% ${id} hidden-label`);
  if (s.colorOverride !== undefined) m.push(`${ind}%% ${id} color: ${s.colorOverride}`);
  if (s.strokeColorOverride !== undefined) m.push(`${ind}%% ${id} stroke: ${s.strokeColorOverride}`);
  if (s.widthMultiplier !== undefined) m.push(`${ind}%% ${id} width: ${s.widthMultiplier.toFixed(2)}`);
  if (s.heightMultiplier !== undefined) m.push(`${ind}%% ${id} height: ${s.heightMultiplier.toFixed(2)}`);
  if (s.lineEnd !== undefined) {
    // Absolut slutposition för lösa linjer/pilar (relativ offset i modellen).
    const ax = swiftRound(s.position.x + s.lineEnd.x);
    const ay = swiftRound(s.position.y + s.lineEnd.y);
    m.push(`${ind}%% ${id} line-end: ${ax},${ay}`);
  }
  if (s.linkNumber !== undefined) m.push(`${ind}%% ${id} link: ${s.linkNumber}`);
  if (s.type === 'table') {
    m.push(`${ind}%% ${id} table: ${s.tableRows ?? 3}×${s.tableCols ?? 3}`);
    const j = encodeCells(s.tableCells);
    if (j !== undefined) m.push(`${ind}%% ${id} table-cells: ${j}`);
  }
  if (SHAPE_TYPE_CARRIED.has(s.type)) m.push(`${ind}%% ${id} shape-type: ${s.type}`);
  m.push(...textMetaLines(s, id, ind));
  m.push(`${ind}%% ${id} pos: ${swiftRound(s.position.x)},${swiftRound(s.position.y)}`);
  if (s.label !== '') m.push(`${ind}%% ${id} name: ${oneLine(s.label)}`);
  if (s.prompt !== '') m.push(`${ind}%% ${id} prompt: ${oneLine(s.prompt)}`);
  return m;
}

/** %%-raderna för en CONTAINER (efter subgraph…end). Ordning = Swift container-loopen. */
export function containerMetaLines(c: ShapeNode, cid: string, ind: string): string[] {
  const m: string[] = [];
  m.push(`${ind}%% ${cid} container-pos: ${swiftRound(c.position.x)},${swiftRound(c.position.y)}`);
  if (c.widthMultiplier !== undefined) m.push(`${ind}%% ${cid} width: ${c.widthMultiplier.toFixed(2)}`);
  if (c.heightMultiplier !== undefined) m.push(`${ind}%% ${cid} height: ${c.heightMultiplier.toFixed(2)}`);
  if (c.skillNumber !== undefined) m.push(`${ind}%% ${cid} skill-nr: ${c.skillNumber}`);
  if (c.prompt !== '') m.push(`${ind}%% ${cid} prompt: ${oneLine(c.prompt)}`);
  if (c.note !== '') m.push(`${ind}%% ${cid} note: ${oneLine(c.note)}`);
  if (!c.showLabel) m.push(`${ind}%% ${cid} hidden-label`);
  if (Math.abs(c.sizeMultiplier - 1.0) > 0.01) m.push(`${ind}%% ${cid} size: ${c.sizeMultiplier.toFixed(1)}`);
  if (Math.abs(c.rotation) > 0.5) m.push(`${ind}%% ${cid} rot: ${swiftRound(c.rotation)}°`);
  if (c.colorOverride !== undefined) m.push(`${ind}%% ${cid} color: ${c.colorOverride}`);
  if (c.strokeColorOverride !== undefined) m.push(`${ind}%% ${cid} stroke: ${c.strokeColorOverride}`);
  m.push(...textMetaLines(c, cid, ind));
  return m;
}

/** Textstil-svansen — identisk i Swifts nod- OCH container-loop (samma nycklar, samma ordning). */
function textMetaLines(s: ShapeNode, id: string, ind: string): string[] {
  const m: string[] = [];
  if (s.textStyle !== 'body') m.push(`${ind}%% ${id} style: ${s.textStyle}`);
  if (s.textAlignment !== 'center') m.push(`${ind}%% ${id} align: ${s.textAlignment}`);
  if (s.hasBullets) m.push(`${ind}%% ${id} bullets`);
  if (s.hasNumberedList) m.push(`${ind}%% ${id} numbered`);
  if (s.indentLevel > 0) m.push(`${ind}%% ${id} indent: ${s.indentLevel}`);
  if (s.locked) m.push(`${ind}%% ${id} locked`);
  if (s.zLayer !== 0) m.push(`${ind}%% ${id} z: ${s.zLayer}`);
  if (s.colorPackId !== undefined) m.push(`${ind}%% ${id} pack: ${s.colorPackId}`);
  return m;
}

/**
 * %%-rader + nativ linkStyle för EN kant — port av MermaidGenerator+Edges (metadata-delen).
 * `appIndex` = kantens plats i edges-arrayen (round-trip via e<i>);
 * `mermaidIndex` = mermaids egen kant-räknare, bara emitterade kanter (för linkStyle).
 */
export function edgeMetaLines(e: EdgeConnection, appIndex: number, mermaidIndex: number,
                              collapsed: boolean, ind: string): string[] {
  const m: string[] = [];
  for (const wp of e.waypoints) m.push(`${ind}%% e${appIndex} waypoint: ${swiftRound(wp.x)},${swiftRound(wp.y)}`);
  if (e.labelPlacement !== 'below') m.push(`${ind}%% e${appIndex} labelPlacement: ${e.labelPlacement}`);
  if (e.colorHex !== undefined) m.push(`${ind}%% e${appIndex} color: ${e.colorHex}`);
  if (e.fromSide !== undefined) m.push(`${ind}%% e${appIndex} fromSide: ${e.fromSide}`);
  if (e.toSide !== undefined) m.push(`${ind}%% e${appIndex} toSide: ${e.toSide}`);
  if (collapsed) m.push(`${ind}%% e${appIndex} collapsed: true`);
  if (e.lineShape !== 'curved') {
    // App-round-trip via %%-raden + NATIV linkStyle interpolate så formen renderar i mermaid.live.
    m.push(`${ind}%% e${appIndex} lineShape: ${e.lineShape}`);
    const interp = e.lineShape === 'straight' ? 'linear' : 'stepAfter';
    m.push(`${ind}linkStyle ${mermaidIndex} interpolate ${interp}`);
  }
  return m;
}

/** Legend-raderna (v71-autofyll) — en per använd kategori; manuell text vinner, annars pickerHint. */
export function legendLines(shapes: readonly ShapeNode[], legend: Readonly<Record<string, string>>): string[] {
  const used = new Set(shapes.map((s) => s.category));
  const out: string[] = [];
  for (const cat of SHAPE_CATEGORIES) {
    if (!used.has(cat)) continue;
    const manual = legend[cat];
    const text = manual !== undefined && manual !== '' ? manual : LEGEND_HINTS[cat];
    out.push(`    %% legend ${cat}: ${oneLine(text)}`);
  }
  return out;
}

/** Trogen port av Swift ShapeCategory.pickerHint — legend-autofyllens standardtexter. */
const LEGEND_HINTS = {
  ui: 'UI-element — text syns på skärmen.',
  zone: 'Layout-zon — region för UI.',
  note: 'Kommentar — syns aldrig som UI-text.',
  overlay: 'Overlay — modal, tooltip, HUD-överlägg.',
  feat: 'Feature — en konkret funktion.',
  milestone: 'Milestone — en version eller leverans.',
  blocker: 'Blocker — hinder eller risk.',
  future: 'Future — idé som inte är med i nuvarande MVP.',
  folder: 'Mapp i kodbasen.',
  file: 'Fil i kodbasen.',
  module: 'Logisk modul eller komponent.',
  service: 'Service / manager / controller.',
  data: 'Datalager eller källa.',
  input: 'Ingångspunkt för data eller event.',
  agent: 'AI-agent eller processlogik.',
  tool: 'Verktyg som agenten anropar.',
  router: 'Villkorad routing eller beslutspunkt.',
  memory: 'Minne eller kontext mellan steg.',
  output: 'Slutpunkt eller resultat.',
  subagent: 'Subagent — delegerad uppgift till annan Claude-instans.',
  prompt: 'Prompt — text till LLM/agent.',
  skill: 'Skill — predefined kapacitet/protokoll.',
  gate: 'Grind — kvalitetskontroll som MÅSTE passeras (≠ router som bara väljer väg).',
  evidence: 'Bevis — sparade belägg (skärmdump, HTML, URL) för spårbarhet.',
  manual: 'Manual — mänsklig kontroll krävs, stoppa automatiken hellre än att gissa.',
  script: 'Script — deterministisk kod (curl/jq/python), ingen LLM-gissning.',
  mcp: 'MCP-server — extern verktygskälla (Model Context Protocol) som Claude Code kan anropa.',
  plugin: 'Plugin — paket av skills/kommandon/hooks för Claude Code.',
  fileMarkdown: 'Markdown-fil (.md) — text, anteckning eller överlämning mellan steg.',
  fileExcel: 'Excel/kalkylark — strukturerad data (tabell, rader).',
  godot_scene: 'Scene-root (.tscn) — motsvarar en skärm.',
  godot_control: 'Control-nod — generisk UI-bas.',
  godot_container: 'Layout-container — VBox/HBox/MarginContainer.',
  godot_panel: 'Panel — yta/kort/bakgrund.',
  godot_button: 'Button — action.',
  godot_label: 'Label — text-element.',
  godot_signal: 'Signal-koppling (för Flow-mode kopplingar).',
  godot_script: 'GDScript-fil med logik.',
} satisfies Record<ShapeCategory, string>;
