// W2-adapter-grinden: domän → tldraw-records → domän = EXAKT samma dokument när inget
// rörts (jämför-före-skriv), och bara det ändrade fältet skiljer när något flyttats.
// Kör mot Kims riktiga v49-fil (129 former, 128 pilar).
import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { parseCanvasFile, parseNativeState, makeShape } from '@v2e/domain';
import {
  docToRecords,
  recordsToDoc,
  recordToShape,
  shapeToRecord,
  typeForGeo,
  type ArrowReading,
} from '../src/mapping.js';
import { richToPlain, plainToRich } from '../src/richtext.js';

const modernPath = fileURLToPath(new URL('../../domain/test/fixtures/native-v49-modern.md', import.meta.url));
const modernState = parseCanvasFile(readFileSync(modernPath, 'utf8')).stateJson!;
const realDoc = parseNativeState(modernState).doc;

/** Simulerad läsning: records som de skulle komma ur editorn (orörda). */
function roundTrip(doc = realDoc) {
  const { shapes, arrows } = docToRecords(doc);
  const tlIdToRecord = new Map(shapes.map((s) => [s.id as string, s] as const));
  const domainToTl = new Map<string, string>();
  for (const s of shapes) {
    const d = (s.meta.domain as { id: string }).id;
    domainToTl.set(d, s.id as string);
  }
  const readings: ArrowReading[] = arrows.map((a) => {
    const edge = a.meta.domain as { from: string; to: string };
    return {
      arrow: a,
      startRecordId: domainToTl.get(edge.from),
      endRecordId: domainToTl.get(edge.to),
    };
  });
  expect(tlIdToRecord.size).toBe(shapes.length);
  return recordsToDoc(shapes, readings);
}

describe('richText fram och tillbaka', () => {
  it('ren text överlever (inkl. radbrytning)', () => {
    expect(richToPlain(plainToRich('Hej'))).toBe('Hej');
    expect(richToPlain(plainToRich('rad 1\nrad 2'))).toBe('rad 1\nrad 2');
    expect(richToPlain(plainToRich(''))).toBe('');
  });
});

describe('round-trip via records — Kims riktiga fil', () => {
  it('orört dokument kommer tillbaka EXAKT lika (djup-lika, alla 129+128)', () => {
    const result = roundTrip();
    expect(result.warnings).toEqual([]);
    expect(result.doc).toEqual(realDoc);
  });

  it('flyttad form: bara den formens position ändras', () => {
    const { shapes, arrows } = docToRecords(realDoc);
    shapes[5]!.x += 100;
    shapes[5]!.y += 50;
    const domainToTl = new Map(shapes.map((s) => [(s.meta.domain as { id: string }).id, s.id as string] as const));
    const readings: ArrowReading[] = arrows.map((a) => {
      const e = a.meta.domain as { from: string; to: string };
      return { arrow: a, startRecordId: domainToTl.get(e.from), endRecordId: domainToTl.get(e.to) };
    });
    const result = recordsToDoc(shapes, readings);
    const orig = realDoc.shapes[5]!;
    const moved = result.doc.shapes[5]!;
    expect(moved.position).toEqual({ x: orig.position.x + 100, y: orig.position.y + 50 });
    expect({ ...moved, position: orig.position }).toEqual(orig);
    // alla andra former exakt orörda
    result.doc.shapes.forEach((s, i) => {
      if (i !== 5) expect(s).toEqual(realDoc.shapes[i]);
    });
  });

  it('okopplad pil ger varning och utelämnas — resten intakt', () => {
    const { shapes, arrows } = docToRecords(realDoc);
    const domainToTl = new Map(shapes.map((s) => [(s.meta.domain as { id: string }).id, s.id as string] as const));
    const readings: ArrowReading[] = arrows.map((a, i) => {
      const e = a.meta.domain as { from: string; to: string };
      return {
        arrow: a,
        startRecordId: i === 3 ? undefined : domainToTl.get(e.from),
        endRecordId: domainToTl.get(e.to),
      };
    });
    const result = recordsToDoc(shapes, readings);
    expect(result.warnings).toHaveLength(1);
    expect(result.doc.edges).toHaveLength(realDoc.edges.length - 1);
  });
});

describe('nya former ritade i tldraw', () => {
  it('v2e-record utan domän i meta blir ny domän-nod med mintat id + rätt typ', () => {
    const rec = shapeToRecord(makeShape({ id: 'tmp', type: 'circle', position: { x: 200, y: 100 }, label: 'Ny' }), 0);
    const bare = { ...rec, meta: {} };
    let minted = 0;
    const node = recordToShape(bare, () => `MINTED-${++minted}`);
    expect(node.id).toBe('MINTED-1');
    expect(node.type).toBe('circle');
    expect(node.label).toBe('Ny');
    expect(node.position).toEqual({ x: 200, y: 100 });
  });

  it('typeForGeo mappar MVP-verktygen', () => {
    expect(typeForGeo('ellipse')).toBe('circle');
    expect(typeForGeo('rectangle')).toBe('rectangle');
    expect(typeForGeo('diamond')).toBe('diamond');
  });

  it('storleksändring i tldraw blir multiplikator i modellen', () => {
    const orig = makeShape({ id: 'a', type: 'rectangle', position: { x: 0, y: 0 } });
    const rec = shapeToRecord(orig, 0);
    rec.props.w = 240; // dubbel bredd (bas 120)
    rec.props.h = 160; // dubbel höjd (bas 80) → uniform → sizeMultiplier
    const node = recordToShape(rec, () => 'x');
    expect(node.sizeMultiplier).toBe(2);
    expect(node.widthMultiplier).toBeUndefined();
  });
});

describe('stil-fält i editorn (jämför-före-skriv)', () => {
  it('ändrad stil-prop skriver BARA det fältet — resten byte-identiskt', () => {
    const { shapes, arrows } = docToRecords(realDoc);
    const rec = shapes[7]!;
    rec.props = { ...rec.props, bold: true, textStyle: 'r2', colorPackId: 'blå' };
    const domainToTl = new Map(shapes.map((s) => [(s.meta.domain as { id: string }).id, s.id as string] as const));
    const readings: ArrowReading[] = arrows.map((a) => {
      const e = a.meta.domain as { from: string; to: string };
      return { arrow: a, startRecordId: domainToTl.get(e.from), endRecordId: domainToTl.get(e.to) };
    });
    const result = recordsToDoc(shapes, readings);
    const orig = realDoc.shapes[7]!;
    const changed = result.doc.shapes[7]!;
    expect(changed.bold).toBe(true);
    expect(changed.textStyle).toBe('r2');
    expect(changed.colorPackId).toBe('blå');
    // toEqual ignorerar undefined-nycklar → orörda fält bevisas byte-identiska
    expect({ ...changed, bold: orig.bold, textStyle: orig.textStyle, colorPackId: orig.colorPackId }).toEqual(orig);
    result.doc.shapes.forEach((s, i) => {
      if (i !== 7) expect(s).toEqual(realDoc.shapes[i]);
    });
  });

  it('egen färg satt och sedan borttagen (\'\') tar bort fältet ur noden', () => {
    const orig = makeShape({ id: 'a', type: 'rectangle', position: { x: 0, y: 0 }, colorOverride: '#ff0000' });
    const rec = shapeToRecord(orig, 0);
    expect(rec.props.color).toBe('#ff0000');
    rec.props = { ...rec.props, color: '' };
    const node = recordToShape(rec, () => 'x');
    expect(node.colorOverride).toBeUndefined();
    expect({ ...node, colorOverride: orig.colorOverride }).toEqual(orig);
  });
});
