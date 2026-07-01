#!/usr/bin/env node
// Webb-arkitektur-grind (Fas 1, minimal): domän-kärnan (@v2e/domain) MÅSTE vara ren — inga externa
// importer (ingen mermaid/react/DOM/nät). Bara relativa './'-importer + node:-inbyggda tillåts.
// (Full dependency-cruiser lager-graf kommer i Fas 2 när fler lager finns.)
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const webRoot = join(here, '..');
const domainSrc = join(webRoot, 'packages', 'domain', 'src');

function walk(dir) {
  const out = [];
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    if (statSync(p).isDirectory()) out.push(...walk(p));
    else if (p.endsWith('.ts')) out.push(p);
  }
  return out;
}

// En ÄKTA import/export-from på en rad. `from\s+` (kräver mellanslag) + specifier utan mellanslag →
// undviker att strängvärdet 'from' i t.ex. Pick<…, 'id' | 'from' | 'to'> tolkas som en import.
const IMPORT_RE = /^[ \t]*(?:import|export)\b[^\n]*?\bfrom\s+['"]([^'"\n]+)['"]/gm;
let bad = 0;
for (const file of walk(domainSrc)) {
  const text = readFileSync(file, 'utf8');
  let m;
  while ((m = IMPORT_RE.exec(text)) !== null) {
    const spec = m[1];
    const ok = spec.startsWith('./') || spec.startsWith('../') || spec.startsWith('node:');
    if (!ok) {
      bad++;
      console.error(`❌ domän-orenhet: ${relative(webRoot, file)} importerar "${spec}" (extern). Domänen ska vara 0-beroende.`);
    }
  }
}
if (bad) {
  console.error(`\n${bad} extern(a) import(er) i domänen — domänen måste vara ren.`);
  process.exit(1);
}
console.log('✅ domän ren (0 externa importer).');
