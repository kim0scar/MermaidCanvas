// Dev-harness: se v2e-formerna utan appen. `npx vite dev packages/canvas/dev`
// Visar alla 16 form-typer + stil-varianter. `#fixture` i URL:en → Kims riktiga v49-fil.
import { createRoot } from 'react-dom/client';
import { Tldraw, type Editor } from 'tldraw';
import 'tldraw/tldraw.css';
import { makeEdge, makeShape, parseCanvasFile, parseNativeState, type CanvasDoc, type ShapeNode } from '@v2e/domain';
import { loadDocIntoEditor } from '../src/index.js';
import { V2E_SHAPE_UTILS } from '../src/native/V2eShapeUtil.js';
import fixture from '../../domain/test/fixtures/native-v49-modern.md?raw';

function demoDoc(): CanvasDoc {
  let i = 0;
  const at = (col: number, row: number) => ({ x: 150 + col * 220, y: 120 + row * 180 });
  const s = (init: Partial<ShapeNode> & Pick<ShapeNode, 'type'>, col: number, row: number) =>
    makeShape({ id: `demo-${i++}`, position: at(col, row), label: init.type, ...init });

  const shapes: ShapeNode[] = [
    s({ type: 'circle', category: 'input' }, 0, 0),
    s({ type: 'rectangle', category: 'ui' }, 1, 0),
    s({ type: 'square', category: 'zone' }, 2, 0),
    s({ type: 'pill', category: 'note' }, 3, 0),
    s({ type: 'diamond', category: 'router' }, 4, 0),
    s({ type: 'processArrow', category: 'script' }, 0, 1),
    s({ type: 'octagon', category: 'gate' }, 1, 1),
    s({ type: 'triangle', category: 'manual' }, 2, 1),
    s({ type: 'cylinder', category: 'evidence' }, 3, 1),
    s({ type: 'link', category: 'ui', linkNumber: 3 }, 4, 1),
    s({ type: 'table', category: 'data', sizeMultiplier: 1.5, tableRows: 3, tableCols: 3, tableCells: [['A', 'B', 'C'], ['1', '2', '3']] }, 0, 2),
    s({ type: 'container', category: 'skill', label: 'Min skill', skillNumber: 2, sizeMultiplier: 1 }, 2, 2),
    s({ type: 'phoneFrame', category: 'ui', label: '' }, 4, 3),
    s({ type: 'line', category: 'ui', showLabel: false }, 0, 3),
    s({ type: 'arrow', category: 'ui', showLabel: false }, 1, 3),
    s({ type: 'emoji', category: 'note', label: '🚀' }, 2, 3),
    // Stil-varianter
    s({ type: 'rectangle', category: 'ui', label: 'Rubrik 1 fet', textStyle: 'r1', bold: true, sizeMultiplier: 1.6 }, 1, 4),
    s({ type: 'rectangle', category: 'ui', label: 'Paket blå', colorPackId: 'blå' }, 3, 4),
    s({ type: 'rectangle', category: 'ui', label: 'Egen mörk', colorOverride: '#0f172a' }, 4, 4),
    s({ type: 'rectangle', category: 'ui', label: 'punkt ett\npunkt två', hasBullets: true, textAlignment: 'leading' }, 0, 5),
    s({ type: 'pill', category: 'note', label: 'kursiv understruken', italic: true, underline: true }, 2, 5),
  ];
  const edges = [
    makeEdge({ id: 'demo-e0', from: 'demo-0', to: 'demo-1', label: 'pil' }),
    makeEdge({ id: 'demo-e1', from: 'demo-4', to: 'demo-6', style: 'dashed', direction: 'bidirectional' }),
  ];
  return { shapes, edges };
}

function onMount(editor: Editor) {
  if (window.location.hash === '#fixture') {
    const parsed = parseCanvasFile(fixture);
    loadDocIntoEditor(editor, parseNativeState(parsed.stateJson!).doc);
  } else {
    loadDocIntoEditor(editor, demoDoc());
  }
}

createRoot(document.getElementById('root')!).render(
  <div style={{ position: 'fixed', inset: 0 }}>
    <Tldraw shapeUtils={V2E_SHAPE_UTILS} onMount={onMount} />
  </div>,
);
