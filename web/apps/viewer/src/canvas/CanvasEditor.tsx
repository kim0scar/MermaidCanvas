// Rit-ytan: tldraw med AVSKALAD verktygsrad — bara det som round-trippar exponeras
// (samma princip som native: typade verktyg → användaren kan inte skapa något som
// inte överlever export). Style-panel/menyer dolda tills fälten har bärare i webben.
import {
  ArrowToolbarItem,
  DefaultToolbar,
  DiamondToolbarItem,
  EllipseToolbarItem,
  EraserToolbarItem,
  HandToolbarItem,
  RectangleToolbarItem,
  SelectToolbarItem,
  Tldraw,
  type Editor,
  type TLComponents,
} from 'tldraw';
import 'tldraw/tldraw.css';

const components: TLComponents = {
  Toolbar: () => (
    <DefaultToolbar>
      <SelectToolbarItem />
      <HandToolbarItem />
      <RectangleToolbarItem />
      <EllipseToolbarItem />
      <DiamondToolbarItem />
      <ArrowToolbarItem />
      <EraserToolbarItem />
    </DefaultToolbar>
  ),
  StylePanel: null,
  MainMenu: null,
  PageMenu: null,
  ActionsMenu: null,
  QuickActions: null,
  HelperButtons: null,
  DebugMenu: null,
  DebugPanel: null,
  ContextMenu: null,
};

export function CanvasEditor({ onMount }: { onMount: (editor: Editor) => void }) {
  return (
    <div className="canvas-wrap">
      <Tldraw components={components} onMount={onMount} />
    </div>
  );
}
