// Rit-ytan: tldraw med HELA default-UI:t av — chromet är vårt eget (iOS-parity).
// Formerna renderas av V2eShapeUtil (native-trogen: kategorifärger, geometri, textstilar).
import { useCallback } from 'react';
import { Tldraw, type Editor, type TLComponents } from 'tldraw';
import { V2E_SHAPE_UTILS } from '@v2e/canvas/shape-util';
import type { TextAlignMode, TextStyle } from '@v2e/domain';
import { EMPTY_SELECTION, type SelectionState } from './selection';
import 'tldraw/tldraw.css';

const components: TLComponents = {
  Toolbar: null,
  StylePanel: null,
  MainMenu: null,
  PageMenu: null,
  NavigationPanel: null,
  ZoomMenu: null,
  Minimap: null,
  ActionsMenu: null,
  QuickActions: null,
  HelperButtons: null,
  HelpMenu: null,
  KeyboardShortcutsDialog: null,
  DebugMenu: null,
  DebugPanel: null,
  ContextMenu: null,
};

function readSelection(editor: Editor): SelectionState {
  const first = editor.getSelectedShapes().find((s) => s.type === 'v2e-shape');
  const count = editor.getSelectedShapeIds().length;
  if (!first) return { ...EMPTY_SELECTION, count };
  const p = first.props as {
    textStyle: TextStyle;
    bold: boolean;
    italic: boolean;
    underline: boolean;
    textAlignment: TextAlignMode;
  };
  return {
    count,
    textStyle: p.textStyle,
    bold: p.bold,
    italic: p.italic,
    underline: p.underline,
    textAlignment: p.textAlignment,
  };
}

export function CanvasEditor({
  onMount,
  onSelection,
  onZoom,
  onTool,
}: {
  onMount: (editor: Editor) => void;
  onSelection: (sel: SelectionState) => void;
  onZoom: (percent: number) => void;
  onTool: (toolId: string) => void;
}) {
  const handleMount = useCallback(
    (editor: Editor) => {
      editor.updateInstanceState({ isGridMode: true });

      // Store-ändringar strömmar tätt — samla per frame, skicka bara faktiska skiften.
      let raf = 0;
      let lastSel = '';
      let lastZoom = -1;
      let lastTool = '';
      const push = () => {
        raf = 0;
        const sel = readSelection(editor);
        const key = JSON.stringify(sel);
        if (key !== lastSel) {
          lastSel = key;
          onSelection(sel);
        }
        const zoom = Math.round(editor.getZoomLevel() * 100);
        if (zoom !== lastZoom) {
          lastZoom = zoom;
          onZoom(zoom);
        }
        const tool = editor.getCurrentToolId();
        if (tool !== lastTool) {
          lastTool = tool;
          onTool(tool);
        }
      };
      const stop = editor.store.listen(
        () => {
          if (!raf) raf = requestAnimationFrame(push);
        },
        { scope: 'all', source: 'all' },
      );
      push();
      onMount(editor);
      return () => {
        if (raf) cancelAnimationFrame(raf);
        stop();
      };
    },
    [onMount, onSelection, onZoom, onTool],
  );

  return (
    <div className="canvas-wrap">
      <Tldraw shapeUtils={V2E_SHAPE_UTILS} components={components} onMount={handleMount} />
    </div>
  );
}
