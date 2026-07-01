// Editor-limmet: ladda ett domändokument in i tldraw-editorn + läs tillbaka det.
// Tunt med flit — all mappningslogik bor i mapping.ts (Node-testbar).
import type { CanvasDoc } from '@v2e/domain';
import type { Editor, TLShapeId } from 'tldraw';
import {
  docToRecords,
  recordsToDoc,
  type ArrowReading,
  type ArrowRecord,
  type GeoRecord,
  type ReadResult,
} from './mapping.js';

/** Rensa sidan och ladda in dokumentet. Zoomar så allt syns (Kims filer ligger ofta långt ut). */
export function loadDocIntoEditor(editor: Editor, doc: CanvasDoc): void {
  const { shapes, arrows, bindings } = docToRecords(doc);
  editor.run(() => {
    const existing = editor.getCurrentPageShapes();
    if (existing.length > 0) editor.deleteShapes(existing.map((s) => s.id));
    if (shapes.length > 0) editor.createShapes(shapes as never[]);
    if (arrows.length > 0) editor.createShapes(arrows as never[]);
    if (bindings.length > 0) editor.createBindings(bindings as never[]);
  }, { history: 'ignore' });
  editor.zoomToFit({ immediate: true });
}

/**
 * Läs editorn → domändokument. Normaliserar efteråt: varje record får `meta.domain` =
 * sitt sparade läge, så nästa läsning jämför mot SENAST SPARAT och nya former behåller
 * sina mintade id:n mellan sparningar.
 */
export function readDocFromEditor(editor: Editor): ReadResult {
  const all = editor.getCurrentPageShapes();
  const geo = all.filter((s) => s.type === 'geo') as unknown as GeoRecord[];
  const arrows = all.filter((s) => s.type === 'arrow') as unknown as ArrowRecord[];

  const readings: ArrowReading[] = arrows.map((a) => {
    const reading: ArrowReading = { arrow: a };
    for (const b of editor.getBindingsFromShape(a.id as TLShapeId, 'arrow')) {
      const props = b.props as { terminal?: 'start' | 'end' };
      if (props.terminal === 'start') reading.startRecordId = b.toId;
      if (props.terminal === 'end') reading.endRecordId = b.toId;
    }
    return reading;
  });

  const result = recordsToDoc(geo, readings);
  normalizeMeta(editor, result);
  return result;
}

/** Skriv tillbaka meta.domain/order så editorn speglar senast lästa/sparade dokument. */
function normalizeMeta(editor: Editor, result: ReadResult): void {
  const nodeIndex = new Map(result.doc.shapes.map((n, i) => [n.id, i] as const));
  const edgeIndex = new Map(result.doc.edges.map((e, i) => [e.id, i] as const));
  const updates: Array<{ id: TLShapeId; type: string; meta: { domain: unknown; order: number } }> = [];

  for (const [recordId, node] of result.nodeByRecordId) {
    updates.push({
      id: recordId as TLShapeId,
      type: 'geo',
      meta: { domain: JSON.parse(JSON.stringify(node)), order: nodeIndex.get(node.id) ?? 0 },
    });
  }
  for (const [recordId, edge] of result.edgeByRecordId) {
    updates.push({
      id: recordId as TLShapeId,
      type: 'arrow',
      meta: { domain: JSON.parse(JSON.stringify(edge)), order: edgeIndex.get(edge.id) ?? 0 },
    });
  }
  if (updates.length > 0) {
    editor.run(() => editor.updateShapes(updates as never[]), { history: 'ignore' });
  }
}
