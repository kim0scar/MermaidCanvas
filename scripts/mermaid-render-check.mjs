// mermaid-render-check.mjs — render-trogen grind (steg H / 💡#8).
//
// Konformitetsgrinden (mermaid-conformance.mjs) kör mermaid.PARSE, som är slappare
// än den riktiga renderaren: t.ex. `<--` (bakåtpil) PARSAR men kraschar render i
// mermaid.live ("Syntax error in text"). Den här grinden RENDERAR varje fixtur i en
// riktig webbläsare (headless Chrome + officiella mermaid.render) och fångar exakt
// det riktig mermaid kraschar på. Körs vid DEPLOY (VERSIONSHANTERING.md), inte varje
// commit — Kims val: snabba commits, full render-koll innan något når en vän.
//
// Kör:  node scripts/mermaid-render-check.mjs            (alla fixtures i mermaid-fixtures/)
//       node scripts/mermaid-render-check.mjs fil.mmd …  (angivna filer)
//
// Exit 0 = alla renderar; exit 1 = minst en kraschar render (eller Chrome saknas).

import { readFileSync, readdirSync, existsSync, writeFileSync, mkdtempSync } from "node:fs";
import { join, dirname } from "node:path";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";

const here = dirname(fileURLToPath(import.meta.url));
const fixturesDir = join(here, "mermaid-fixtures");

// CDN-version låst till samma major som konformitetsgrindens node-paket (11.x).
const MERMAID_CDN = "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";

// --- Hitta en Chrome/Chromium ---
const CHROME_CANDIDATES = [
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  "/Applications/Chromium.app/Contents/MacOS/Chromium",
  "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
  "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser",
];
const chrome = CHROME_CANDIDATES.find((p) => existsSync(p));
if (!chrome) {
  console.error("⚠️  render-grind: ingen Chrome/Chromium hittad. Installera Google Chrome (renderar = sanningen, parse räcker inte).");
  process.exit(1);
}

// --- Vilka filer? ---
const args = process.argv.slice(2);
let files = args.length
  ? args
  : (existsSync(fixturesDir)
      ? readdirSync(fixturesDir).filter((f) => f.endsWith(".mmd")).map((f) => join(fixturesDir, f)).sort()
      : []);
if (!files.length) {
  console.error("⚠️  render-grind: inga .mmd-fixtures att rendera.");
  process.exit(1);
}

const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
const tmp = mkdtempSync(join(tmpdir(), "mmd-render-"));

function renderTitle(text) {
  const html = `<!DOCTYPE html><html><head><meta charset="utf-8"></head><body>
<div id="src" style="display:none">${esc(text)}</div>
<script type="module">
import mermaid from "${MERMAID_CDN}";
mermaid.initialize({ startOnLoad:false, securityLevel:"loose" });
const t = document.getElementById("src").textContent;
try { await mermaid.render("o", t); document.title = "MERMAID_OK"; }
catch(e){ document.title = "MERMAID_ERR:" + String(e && e.message || e).split("\\n")[0]; }
</script></body></html>`;
  const htmlPath = join(tmp, "r.html");
  writeFileSync(htmlPath, html);
  const dom = execFileSync(chrome, [
    "--headless=new", "--disable-gpu", "--no-sandbox",
    "--virtual-time-budget=10000", "--dump-dom", `file://${htmlPath}`,
  ], { encoding: "utf8", timeout: 30000, maxBuffer: 64 * 1024 * 1024 });
  const m = dom.match(/<title>([^<]*)<\/title>/);
  return m ? m[1] : "MERMAID_ERR:ingen render (timeout/CDN?)";
}

let failed = 0;
for (const file of files) {
  const text = readFileSync(file, "utf8");
  const name = file.replace(here + "/", "").replace(process.cwd() + "/", "");
  let title;
  try { title = renderTitle(text); }
  catch (e) { title = "MERMAID_ERR:" + String(e?.message ?? e).split("\n")[0]; }
  if (title === "MERMAID_OK") {
    console.log(`✅ ${name}  (renderar i riktig mermaid)`);
  } else {
    failed++;
    console.error(`❌ ${name}\n   ${title.replace(/^MERMAID_ERR:/, "")}`);
  }
}

console.log(`\n${files.length - failed}/${files.length} renderar i RIKTIG mermaid (headless Chrome).`);
process.exit(failed ? 1 : 0);
