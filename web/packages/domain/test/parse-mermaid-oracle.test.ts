// GULD-ORAKLET (Tier 2-parsern): samma riktiga app-fil läses via BÅDA vägarna —
// (1) parseMermaidBody på mermaid-kroppen (utan state-blocket) och
// (2) parseNativeState på state-JSON — och allt som bärs av %%-nycklar ska bli LIKA.
//
// FÖRVÄNTADE LUCKOR (state-JSON-only enligt capabilities.ts FEATURES / EXTENDED-FORMAT.md
// — blir DEFAULT i Tier 2, aldrig tyst fel):
//   - bold / italic / underline  → alltid false i Tier 2 (inget %%-spår)
//   - subCanvas (PARKERAT Visio-underflöde) → alltid undefined i Tier 2
//   - phoneFrame-barn (childOfContainerId till phoneFrame) → bara state-JSON
//   - exakt backward-RIKTNING → ren mermaid skriver omvänd framåtpil (to-->from)
// AVRUNDNING (inte luckor): %%-lagret skriver pos/waypoints/rot som HELTAL medan
// state-JSON har exakta doubles → tolerans ±0.5 på dessa fält.
import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { parseCanvasFile, parseMermaidBody, parseNativeState } from '../src/index.js';
import type { ShapeNode } from '../src/index.js';

const modernMd = readFileSync(
  fileURLToPath(new URL('./fixtures/native-v49-modern.md', import.meta.url)), 'utf8');
const legacyMd = readFileSync(
  fileURLToPath(new URL('./fixtures/native-alla-former.md', import.meta.url)), 'utf8');

const modern = parseCanvasFile(modernMd);
const tier2 = parseMermaidBody(modern.mermaid).doc;
const tier1 = parseNativeState(modern.stateJson!).doc;

/** Fält som jämförs EXAKT (bärs av %%-nycklar/nod-kroppen). */
function exactFields(s: ShapeNode) {
  return {
    type: s.type,
    category: s.category,
    label: s.label,
    note: s.note,
    prompt: s.prompt,
    showLabel: s.showLabel,
    sizeMultiplier: s.sizeMultiplier,
    widthMultiplier: s.widthMultiplier,
    heightMultiplier: s.heightMultiplier,
    textStyle: s.textStyle,
    textAlignment: s.textAlignment,
    hasBullets: s.hasBullets,
    hasNumberedList: s.hasNumberedList,
    indentLevel: s.indentLevel,
    locked: s.locked,
    zLayer: s.zLayer,
    colorOverride: s.colorOverride,
    strokeColorOverride: s.strokeColorOverride,
    linkNumber: s.linkNumber,
    skillNumber: s.skillNumber,
    tableRows: s.tableRows,
    tableCols: s.tableCols,
    tableCells: s.tableCells,
    colorPackId: s.colorPackId,
    childOfContainerId: s.childOfContainerId,
  };
}

describe('guld-oraklet: native-v49-modern.md — %%-burna fält == state-JSON', () => {
  const byId = new Map(tier2.shapes.map((s) => [s.id, s]));

  it('samma nod-mängd (inga tappade noder, inga fantom-noder)', () => {
    expect(tier2.shapes.map((s) => s.id).sort()).toEqual(tier1.shapes.map((s) => s.id).sort());
    expect(tier1.shapes).toHaveLength(129);
  });

  it('alla %%-burna nod-fält är LIKA fält-för-fält', () => {
    for (const ref of tier1.shapes) {
      const got = byId.get(ref.id)!;
      expect(exactFields(got), `nod ${ref.id}`).toEqual(exactFields(ref));
    }
  });

  it('positioner lika inom %%-avrundningen (±0.5)', () => {
    for (const ref of tier1.shapes) {
      const got = byId.get(ref.id)!;
      expect(Math.abs(got.position.x - ref.position.x), `x för ${ref.id}`).toBeLessThanOrEqual(0.5);
      expect(Math.abs(got.position.y - ref.position.y), `y för ${ref.id}`).toBeLessThanOrEqual(0.5);
    }
  });

  it('förväntade luckor är DEFAULT — inte skräpvärden', () => {
    for (const got of tier2.shapes) {
      expect(got.bold).toBe(false);
      expect(got.italic).toBe(false);
      expect(got.underline).toBe(false);
      expect(got.subCanvas).toBeUndefined();
    }
  });

  it('kanter: antal + from/to/etikett/riktning/stil/meta lika, waypoints inom ±0.5', () => {
    expect(tier2.edges).toHaveLength(tier1.edges.length);
    expect(tier1.edges).toHaveLength(128);
    tier1.edges.forEach((ref, i) => {
      const got = tier2.edges[i]!;
      expect(
        {
          from: got.from, to: got.to, label: got.label, direction: got.direction,
          style: got.style, labelPlacement: got.labelPlacement, colorHex: got.colorHex,
          fromSide: got.fromSide, toSide: got.toSide, lineShape: got.lineShape,
        },
        `kant ${i}`,
      ).toEqual({
        from: ref.from, to: ref.to, label: ref.label, direction: ref.direction,
        style: ref.style, labelPlacement: ref.labelPlacement, colorHex: ref.colorHex,
        fromSide: ref.fromSide, toSide: ref.toSide, lineShape: ref.lineShape,
      });
      expect(got.waypoints, `waypoints-antal kant ${i}`).toHaveLength(ref.waypoints.length);
      ref.waypoints.forEach((wp, j) => {
        expect(Math.abs(got.waypoints[j]!.x - wp.x), `wp x kant ${i}`).toBeLessThanOrEqual(0.5);
        expect(Math.abs(got.waypoints[j]!.y - wp.y), `wp y kant ${i}`).toBeLessThanOrEqual(0.5);
      });
    });
  });
});

describe('legacy-fixturen: native-alla-former.md (v35.1-era)', () => {
  // DOKUMENTERAT: resultatet FÅR skilja från dess state-JSON — filen är från eran
  // FÖRE %% shape-type (v67), så app-egna typer (table/link/line/arrow) i state-blocket
  // syns i kroppen bara som rektanglar. Kravet här: parsas utan krasch + rimlig struktur.
  it('kroppen parsas utan krasch och ger stabil grundstruktur', () => {
    const { doc } = parseMermaidBody(parseCanvasFile(legacyMd).mermaid);
    expect(doc.shapes).toHaveLength(9);
    expect(doc.edges).toHaveLength(7);
    const byId = new Map(doc.shapes.map((s) => [s.id, s]));
    expect(byId.get('ui_N0')!.type).toBe('circle');
    expect(byId.get('ui_N2')!.type).toBe('diamond');
    expect(byId.get('ui_N3')!.type).toBe('pill');
    expect(byId.get('ui_N5')!.type).toBe('rectangle'); // state säger "table" — %% shape-type fanns inte än
    expect(byId.get('ui_N1')!.sizeMultiplier).toBe(1.5);
    expect(byId.get('ui_N0')!.position).toEqual({ x: 1800, y: 1750 });
    expect(doc.edges[2]).toMatchObject({ from: 'ui_N2', to: 'ui_N3', label: 'Ja', direction: 'forward' });
    expect(doc.edges[6]).toMatchObject({ from: 'ui_N4', to: 'ui_N7', style: 'dashed' });
  });
});
