// Flytande förhandsvisning under drag-ut (motsvarar native FloatingChipPreview).
import type { ChipDragState } from './useChipDrag';
import { ShapeGlyph } from './ShapeGlyph';

export function ChipDragGhost({ drag }: { drag: ChipDragState | null }) {
  if (!drag) return null;
  return (
    <div
      style={{
        position: 'fixed',
        left: drag.x,
        top: drag.y,
        transform: 'translate(-50%, -50%) scale(2)',
        opacity: 0.85,
        pointerEvents: 'none',
        zIndex: 1000,
      }}
    >
      <ShapeGlyph type={drag.type} />
    </div>
  );
}
