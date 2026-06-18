#!/usr/bin/env node
// MermaidCanvas — maskinell konformitetsgrind (steg 7).
//
// Validerar att appens GENERERADE mermaid faktiskt parsar i RIKTIG mermaid
// (samma grammatik som renderaren på mermaid.live). Då vet vi att canvasen blir
// "exakt såsom Kim ser den". Kompletterar de interna round-trip-testerna, som bara
// bevisar att appen kan läsa sin egen text — INTE att riktig mermaid accepterar den.
//
// Verktyg: officiella npm-paketet `mermaid` (mermaid.parse) ovanpå en jsdom-DOM.
// Valt efter spike 2026-06-18: @probelabs/maid gav FALSKA fel (avslutande ; på
// classDef, citat i cylinder) → inte troget riktig mermaid. mmdc kräver 1,7 GB
// Chrome. mermaid.parse + jsdom = den officiella grammatiken, lätt, inga falska fel.
//
// Kör:  node scripts/mermaid-conformance.mjs            (validerar scripts/mermaid-fixtures/*.mmd)
//       node scripts/mermaid-conformance.mjs fil.mmd …  (validerar angivna filer)
// Exit 0 = allt giltigt. Exit 1 = minst en fil parsar inte (eller saknade beroenden).

import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join, dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..");
const fixturesDir = join(here, "mermaid-fixtures");

// --- Beroende-koll: säg tydligt till om npm install inte körts ---
const need = join(repoRoot, "node_modules", "mermaid");
if (!existsSync(need)) {
  console.error("⚠️  mermaid-grind: node_modules saknas. Kör `npm install` i projektroten först.");
  process.exit(1);
}

// --- DOM-skal (mermaid är webbläsar-orienterad; parse kräver document/window) ---
const { JSDOM } = await import("jsdom");
const dom = new JSDOM("<!DOCTYPE html><body></body>", { url: "http://localhost/" });
globalThis.window = dom.window;
globalThis.document = dom.window.document;

const mermaid = (await import("mermaid")).default;
mermaid.initialize({ startOnLoad: false, securityLevel: "loose" });

// --- Vilka filer? Argument > fixtures-mappen ---
const args = process.argv.slice(2);
let files;
if (args.length) {
  files = args;
} else {
  if (!existsSync(fixturesDir)) {
    console.error(`⚠️  Hittar inte ${fixturesDir}. Generera fixtures via MermaidConformanceCorpusTests.`);
    process.exit(1);
  }
  files = readdirSync(fixturesDir)
    .filter((f) => f.endsWith(".mmd"))
    .map((f) => join(fixturesDir, f))
    .sort();
}

if (!files.length) {
  console.error("⚠️  Inga .mmd-fixtures att validera.");
  process.exit(1);
}

let failed = 0;
for (const file of files) {
  const text = readFileSync(file, "utf8");
  const name = file.replace(repoRoot + "/", "");
  try {
    const r = await mermaid.parse(text);
    console.log(`✅ ${name}  (${r?.diagramType ?? "ok"})`);
  } catch (e) {
    failed++;
    const msg = String(e?.message ?? e).split("\n").slice(0, 3).join(" / ");
    console.error(`❌ ${name}\n   ${msg}`);
  }
}

console.log(`\n${files.length - failed}/${files.length} giltiga mot riktig mermaid.`);
process.exit(failed ? 1 : 0);
