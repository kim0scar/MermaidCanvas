// SINGLE SOURCE OF TRUTH för "vad appen kan visa → vad en AI får använda i mermaid".
// Trogen TS-port av Swift AppCapabilities.swift (app/MermaidCanvas/Sources/App/Models/).
// REN: inga beroenden (ingen React/nät/DOM).
//
// Currency tvingas: SHAPE_CAPABILITIES täcker VARJE ShapeType via `satisfies
// Record<ShapeType, ShapeCapability>` → en ny form utan rad kompilerar inte (speglar
// Swifts uttömmande switch). Bijektion mot TS-generatorns %%-nycklar bevisas i
// test/capabilities.test.ts (CLAUDE.md regel 15).

import { SHAPE_TYPES, type ShapeType } from './model.js';

/** Swift AppVersion.version vid porteringen — stämplas i frameworkText. */
export const SOURCE_APP_VERSION = '1.5.7';

/** Hur en form bärs i mermaid. */
export interface ShapeCapability {
  displayName: string;
  /** Hur den renderas i RIKTIG mermaid (mermaid.live). */
  mermaidForm: string;
  /** true = egen form: visas som närmaste native-form, identiteten bärs av `%% shape-type`. */
  appOnly: boolean;
}

/** Uttömmande → ny ShapeType tvingar en rad (kompileringsfel annars). */
export const SHAPE_CAPABILITIES = {
  circle:       { displayName: 'Cirkel',            mermaidForm: '((text)) — native', appOnly: false },
  rectangle:    { displayName: 'Rektangel',         mermaidForm: '[text] — native', appOnly: false },
  diamond:      { displayName: 'Romb (beslut)',     mermaidForm: '{text} — native', appOnly: false },
  pill:         { displayName: 'Kapsel',            mermaidForm: '([text]) stadium — native', appOnly: false },
  cylinder:     { displayName: 'Cylinder',          mermaidForm: '[(text)] — native', appOnly: false },
  container:    { displayName: 'Container / Skill', mermaidForm: 'subgraph … end — native', appOnly: false },
  square:       { displayName: 'Kvadrat',           mermaidForm: 'rektangel + %% shape-type: square', appOnly: true },
  processArrow: { displayName: 'Processpil',        mermaidForm: 'rektangel + %% shape-type: processArrow', appOnly: true },
  octagon:      { displayName: 'Oktagon',           mermaidForm: 'rektangel + %% shape-type: octagon', appOnly: true },
  triangle:     { displayName: 'Triangel',          mermaidForm: 'rektangel + %% shape-type: triangle', appOnly: true },
  phoneFrame:   { displayName: 'iPhone-ram',        mermaidForm: 'rektangel + %% shape-type: phoneFrame', appOnly: true },
  table:        { displayName: 'Tabell',            mermaidForm: 'rektangel + %% table-cells', appOnly: true },
  link:         { displayName: 'Hopplänk',          mermaidForm: 'cirkel + %% link: N', appOnly: true },
  line:         { displayName: 'Lös linje',         mermaidForm: 'nod + %% shape-type: line', appOnly: true },
  arrow:        { displayName: 'Lös pil',           mermaidForm: 'nod + %% shape-type: arrow', appOnly: true },
  emoji:        { displayName: 'Emoji',             mermaidForm: 'text-nod + %% shape-type: emoji', appOnly: true },
} satisfies Record<ShapeType, ShapeCapability>;

/** App-egna FUNKTIONER (inte former) — bärs i mermaid utan att skada den. */
export interface FeatureCapability {
  name: string;
  /** Var den bärs (mermaid-syntax / `%%`-nyckel / state-JSON). */
  carrier: string;
  /** Överlever den i REN mermaid (utan state-blocket — en väns vy)? */
  survivesPureMermaid: boolean;
}

export const FEATURES: readonly FeatureCapability[] = [
  { name: 'Position',            carrier: '%% pos: x,y + state-JSON',            survivesPureMermaid: true },
  { name: 'Storlek (bredd/höjd)', carrier: '%% size/width/height + state-JSON',  survivesPureMermaid: true },
  { name: 'Rotation',            carrier: '%% rot: N° + state-JSON',             survivesPureMermaid: true },
  { name: 'Kategori-färg',       carrier: ':::klass + classDef — native',        survivesPureMermaid: true },
  { name: 'Egen färg (override)', carrier: '%% color/stroke + state-JSON',       survivesPureMermaid: true },
  { name: '🔒 Lås',              carrier: '%% locked + state-JSON',              survivesPureMermaid: true },
  { name: '📚 Lager (z)',        carrier: '%% z: N + state-JSON',                survivesPureMermaid: true },
  { name: 'Textjustering/listor/indrag', carrier: '%% align/bullets/numbered/indent', survivesPureMermaid: true },
  { name: 'Fet/kursiv/understruken', carrier: 'BARA state-JSON (bold/italic/underline)', survivesPureMermaid: false },
  { name: 'Prompt (skill-former)', carrier: '%% prompt + state-JSON',            survivesPureMermaid: true },
  { name: 'Anteckning',          carrier: '%% note + state-JSON',                survivesPureMermaid: true },
  { name: 'Kollaps (gren)',      carrier: '%% e<i> collapsed + state-JSON',      survivesPureMermaid: true },
  { name: 'Pil-waypoints/böj',   carrier: '%% e<i> waypoint + state-JSON',       survivesPureMermaid: true },
  { name: 'Pil-färg/sidor/etikett-pos', carrier: '%% e<i> color/fromSide/toSide/labelPlacement', survivesPureMermaid: true },
  { name: 'Pil-linjeform (rak/böjd/vinklad)', carrier: '%% e<i> lineShape + linkStyle interpolate + state-JSON', survivesPureMermaid: true },
  { name: 'Visio hoppa-in (underflöde) — PARKERAT', carrier: 'subCanvas i state-JSON, AVSTÄNGT (FeatureFlags.underflodenEnabled=false); återupptas bara som native subgraph', survivesPureMermaid: false },
  { name: 'Bakåtpil',            carrier: 'skrivs som omvänd framåtpil (to-->from)', survivesPureMermaid: true },
  { name: 'Container-förälder',  carrier: 'subgraph-medlemskap + state-JSON',    survivesPureMermaid: true },
  { name: 'phoneFrame-förälder', carrier: 'BARA state-JSON (childOfContainerId)', survivesPureMermaid: false },
  { name: 'Canvas-storlek',      carrier: '%% canvas-size: w,h + state-JSON',    survivesPureMermaid: true },
  { name: 'Skill-nummer',        carrier: '%% skill-nr + state-JSON',            survivesPureMermaid: true },
];

/**
 * ALLA `%%`-nyckel-tokens som FILFORMATET använder (port av Swift allCarrierKeys).
 * Testet capabilities.test.ts kollar att TS-generatorns faktiska nycklar bara kommer
 * härifrån (ingen odokumenterad nyckel).
 */
export const ALL_CARRIER_KEYS: ReadonlySet<string> = new Set([
  // nod + container
  'pos', 'name', 'size', 'width', 'height', 'rot', 'hidden-label',
  'color', 'stroke', 'link', 'skill-nr', 'table', 'table-cells',
  'shape-type', 'style', 'align', 'bullets', 'numbered', 'indent',
  'locked', 'z', 'pack', 'line-end', 'prompt', 'note', 'container-pos',
  // canvas-nivå + kant
  'canvas-size', 'legend', 'waypoint', 'labelPlacement', 'fromSide', 'collapsed',
  'toSide',      // 1.3: inkommande sida på mål-formen
  'lineShape',   // v1.0: form på linjen (rak/böjd/vinklad)
]);

/**
 * ÄRLIGT GAP: nycklar i filformatet som TS-generatorn ännu INTE emitterar.
 * TOM sedan %%-metadata-porten (generate-meta.ts) — webben emitterar alla nycklar
 * med Swifts villkor/format. Testet kräver: emitterade ∪ denna lista == ALL_CARRIER_KEYS,
 * disjunkt — listan kan aldrig ljuga.
 */
export const NOT_YET_EMITTED_BY_WEB: ReadonlySet<string> = new Set();

/**
 * FLAGG-nycklar: skrivs UTAN kolon/värde (`%% <id> locked`) — samma grammatik som Swift
 * MermaidMetaComments, som special-casar exakt dessa fyra. Bijektions-testet behöver
 * listan för att känna igen flagg-emission i generator-källkoden.
 */
export const FLAG_CARRIER_KEYS: ReadonlySet<string> = new Set([
  'hidden-label', 'bullets', 'numbered', 'locked',
]);

/**
 * AI-RAMVERKET — copy-paste till en AI så den vet exakt vad den får rita i mermaid
 * för att appen ska kunna importera det. Genereras ur koden (alltid aktuell).
 * Port av Swift frameworkText(); TS-tillägg: ShapeType-token i parentes per form.
 */
export function frameworkText(version: string = SOURCE_APP_VERSION): string {
  let s = `# MermaidCanvas — vad du får använda i mermaid (genererat ${version})\n\n`;
  s += 'Appen är ett TVÅ-LAGER-system: mermaid är transporten, appen lägger till ett eget lager via\n';
  s += '`%%`-kommentarer + ett `<!-- mermaidcanvas-state … -->`-block. Rita med vanlig flowchart-syntax.\n\n';
  s += '## NATIVE mermaid-former (renderas identiskt)\n';
  for (const t of SHAPE_TYPES) {
    const c = SHAPE_CAPABILITIES[t];
    if (!c.appOnly) s += `- **${c.displayName}** (\`${t}\`) → \`${c.mermaidForm}\`\n`;
  }
  s += '\n## EGNA former (ritas som närmaste native; identitet via `%% shape-type`)\n';
  for (const t of SHAPE_TYPES) {
    const c = SHAPE_CAPABILITIES[t];
    if (c.appOnly) s += `- **${c.displayName}** (\`${t}\`) → ${c.mermaidForm}\n`;
  }
  s += '\n## Kanter\n- `A --> B` (pil) · `A -.-> B` (streckad) · `A <--> B` (dubbelriktad) · `A --- B` (ingen pil)\n';
  s += '- Bakåtpil finns INTE i mermaid → skriv `B --> A` (omvända noder).\n';
  s += '\n## APP-EGNA funktioner (bärs i mermaid utan skada)\n';
  for (const f of FEATURES) {
    s += `- **${f.name}** → \`${f.carrier}\`${f.survivesPureMermaid ? '' : '  ⚠️ bara i state-blocket'}\n`;
  }
  s += '\n> Lägger du till en form/funktion utan att uppdatera detta + round-trippa = brott mot CLAUDE.md regel 15.\n';
  return s;
}
