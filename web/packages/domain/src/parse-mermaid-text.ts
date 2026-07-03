// Text-/regex-delen av Tier 2-parsern — port av Swift MermaidParser+TextHelpers.swift
// + nod-/kant-mönstren ur MermaidParser.parseMermaid. Rena strängoperationer,
// inga beroenden till parserns orkestrering. Swift är facit — mönstren är 1:1.

import {
  type ShapeCategory,
  type ShapeType,
  SHAPE_CATEGORIES,
} from './model.js';

export interface ParsedNode {
  mermaidId: string;
  type: ShapeType;
  label: string;
  category: ShapeCategory;
}

export interface RawEdge {
  from: string;
  arrow: string;
  label: string;
  to: string;
}

const isCategory = (v: string): v is ShapeCategory =>
  (SHAPE_CATEGORIES as readonly string[]).includes(v);

/** #quot; och <br/> tillbaka till citattecken/radbrytning (omvänd escape). */
export function unescapeLabel(s: string): string {
  return s.split('#quot;').join('"').split('<br/>').join('\n');
}

/** v31: deprecated kategorier (Roadmap/Arkitektur-pack) migreras till note. */
function migrateDeprecated(cat: ShapeCategory): ShapeCategory {
  switch (cat) {
    case 'feat': case 'milestone': case 'blocker': case 'future':
    case 'folder': case 'file': case 'module': case 'service': case 'data':
      return 'note';
    default:
      return cat;
  }
}

/** Kategori i fallback-läge: först :::klass-suffix, annars prefix i id (ui_xxx), annars ui. */
export function categoryFor(mermaidId: string, classRaw: string | undefined): ShapeCategory {
  if (classRaw !== undefined && isCategory(classRaw)) return migrateDeprecated(classRaw);
  const underscore = mermaidId.indexOf('_');
  if (underscore !== -1) {
    const prefix = mermaidId.slice(0, underscore);
    if (isCategory(prefix)) return migrateDeprecated(prefix);
  }
  return 'ui';
}

/**
 * v61: Skala bort nod-kroppar och kommentarer inför kant-parsning.
 * `a["Träffa (kanske) Bo"] --> b{Val}` → `a --> b`. Innersta klamrar först,
 * upprepat tills inget ändras. Normaliserar även äldre pil-skrivsätt.
 */
export function stripNodeBodies(block: string): string {
  // %%-kommentarer bort (kan innehålla pil-tecken i notis/prompt-text)
  let s = block.split('\n').filter((l) => !l.trim().startsWith('%%')).join('\n');
  const bracketPatterns = [/\([^()]*\)/g, /\[[^\[\]]*\]/g, /\{[^{}]*\}/g];
  let changed = true;
  while (changed) {
    changed = false;
    for (const re of bracketPatterns) {
      const next = s.replace(re, '');
      if (next !== s) { s = next; changed = true; }
    }
  }
  // :::kategori-suffix bort (annars blir "ui" i `a:::ui --> b` en fantomnod)
  s = s.replace(/:::\w+/g, '');
  // `a -- text --> b` → `a -->|text| b` osv; tjocka pilar → vanliga.
  s = s.replace(/--\s+([^-<>|\n]+?)\s+-->/g, '-->|$1|');
  s = s.replace(/-\.\s+([^-<>|\n]+?)\s+\.->/g, '-.->|$1|');
  s = s.replace(/==\s+([^=<>|\n]+?)\s+==>/g, '==>|$1|');
  s = s.replace(/<=+>/g, '<-->');
  s = s.replace(/=+>/g, '-->');
  return s;
}

/** Nod-id-prefix på en rad (Swift isLetter/isNumber/underscore). */
export function leadingIdent(line: string): string {
  const m = /^[\p{L}\p{N}_]+/u.exec(line);
  return m ? m[0] : '';
}

// Former; valfritt :::klass-suffix. Ordning: circle/pill före rektangel (som Swift).
// Citerade testas först; seen-mängden skyddar mot dubbel-parse av ocitat.
const NODE_PATTERNS: ReadonlyArray<readonly [RegExp, ShapeType]> = [
  [/(\w+)\(\(\s*"([^"]*?)"\s*\)\)(?::::(\w+))?/g, 'circle'],     // ((".."))
  [/(\w+)\(\[\s*"([^"]*?)"\s*\]\)(?::::(\w+))?/g, 'pill'],       // ([".."])
  [/(\w+)\[\(\s*"([^"]*?)"\s*\)\](?::::(\w+))?/g, 'cylinder'],   // [("..")]
  [/(\w+)\(\s*"([^"]*?)"\s*\)(?::::(\w+))?/g, 'rectangle'],      // ("..")
  [/(\w+)\[\s*"([^"]*?)"\s*\](?::::(\w+))?/g, 'rectangle'],      // [".."] bakåtkomp
  [/(\w+)\{\s*"([^"]*?)"\s*\}(?::::(\w+))?/g, 'diamond'],        // {".."}
  [/(\w+)\(\(\s*([^)"]+?)\s*\)\)(?::::(\w+))?/g, 'circle'],      // ((..)) ocitat
  [/(\w+)\(\[\s*([^\]"]+?)\s*\]\)(?::::(\w+))?/g, 'pill'],       // ([..]) ocitat
  [/(\w+)\[\(\s*([^)"]+?)\s*\)\](?::::(\w+))?/g, 'cylinder'],    // [(..)] ocitat
  [/(\w+)\(\s*([^)"]+?)\s*\)(?::::(\w+))?/g, 'rectangle'],       // (..) ocitat
  [/(\w+)\[\s*([^\]"]+?)\s*\](?::::(\w+))?/g, 'rectangle'],      // [..] ocitat
  [/(\w+)\{\s*([^}"]+?)\s*\}(?::::(\w+))?/g, 'diamond'],         // {..} ocitat
];

// v61: tre subgraph-varianter — ["Label"], [Label] och bara `subgraph id`.
const SUBGRAPH_PATTERNS: readonly RegExp[] = [
  /subgraph\s+(\w+)\s*\[\s*"([^"]*?)"\s*\]/gm,
  /subgraph\s+(\w+)\s*\[\s*([^\]"]+?)\s*\]/gm,
  /subgraph\s+(\w+)\s*$/gm,
];

// Alla 8 pil-kombinationer; längre/mer specifika först (som Swift).
const EDGE_PATTERN = /(\w+)\s*(<-+\.->|<-+->|-+\.->|-+->|<-+\.-+|<-+|-+\.-+|-{3,})\s*(?:\|\s*"?([^"|]*?)"?\s*\|\s*)?(\w+)/g;

/**
 * Deklarerade noder ur blocket: subgraphs FÖRST (v44 — blir containrar), sedan
 * form-mönstren. `seen` muteras så anroparen kan lägga till nakna id:n efteråt.
 */
export function collectDeclaredNodes(block: string, seen: Set<string>): ParsedNode[] {
  const nodes: ParsedNode[] = [];
  for (const pattern of SUBGRAPH_PATTERNS) {
    for (const m of block.matchAll(pattern)) {
      const id = m[1]!;
      // v46: hoppa över iphone-wrapper-subgraphen (inte en användarcontainer)
      if (seen.has(id) || id === 'iphone') continue;
      seen.add(id);
      const label = m[2] !== undefined ? unescapeLabel(m[2]) : id;
      nodes.push({ mermaidId: id, type: 'container', label, category: categoryFor(id, undefined) });
    }
  }
  for (const [pattern, type] of NODE_PATTERNS) {
    for (const m of block.matchAll(pattern)) {
      const id = m[1]!;
      if (seen.has(id)) continue;
      seen.add(id);
      nodes.push({ mermaidId: id, type, label: unescapeLabel(m[2]!), category: categoryFor(id, m[3]) });
    }
  }
  return nodes;
}

/** Kant-rader som råa id-par, i dokumentordning (letas i det AVSKALADE blocket). */
export function collectRawEdges(block: string): RawEdge[] {
  const rawEdges: RawEdge[] = [];
  for (const m of stripNodeBodies(block).matchAll(EDGE_PATTERN)) {
    rawEdges.push({ from: m[1]!, arrow: m[2]!, label: m[3] ?? '', to: m[4]! });
  }
  return rawEdges;
}
