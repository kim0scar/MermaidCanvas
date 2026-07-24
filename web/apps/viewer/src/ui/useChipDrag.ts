// Drag-ut från form-chips (port av native ToolbarView+Chips drag-gesten):
// pointerdown → >8px rörelse = drag-läge med flytande ghost → släpp över canvasen
// = form på släpp-punkten. Under 8px = vanligt tryck (onClick går igenom).
// Pointer events (inte HTML5-drag) — det enda som funkar för touch på iOS Safari.
import { useCallback, useRef, useState } from 'react';
import type { ShapeType } from '@v2e/domain';

const DRAG_THRESHOLD = 8;

export interface ChipDragState {
  type: ShapeType;
  x: number;
  y: number;
}

export function useChipDrag(onDrop: (type: ShapeType, client: { x: number; y: number }) => void) {
  const [drag, setDrag] = useState<ChipDragState | null>(null);
  const start = useRef<{ type: ShapeType; x: number; y: number } | null>(null);
  const dragging = useRef(false);

  const getChipProps = useCallback(
    (type: ShapeType) => ({
      onPointerDown: (e: React.PointerEvent<HTMLButtonElement>) => {
        start.current = { type, x: e.clientX, y: e.clientY };
        dragging.current = false;
        e.currentTarget.setPointerCapture(e.pointerId);
      },
      onPointerMove: (e: React.PointerEvent<HTMLButtonElement>) => {
        const s = start.current;
        if (!s) return;
        if (!dragging.current) {
          const dist = Math.hypot(e.clientX - s.x, e.clientY - s.y);
          if (dist < DRAG_THRESHOLD) return;
          dragging.current = true;
        }
        setDrag({ type: s.type, x: e.clientX, y: e.clientY });
      },
      onPointerUp: (e: React.PointerEvent<HTMLButtonElement>) => {
        const s = start.current;
        start.current = null;
        setDrag(null);
        if (!s || !dragging.current) return; // vanligt tryck — onClick tar det
        // Släpp bara om punkten ligger över rit-ytan
        const el = document.elementFromPoint(e.clientX, e.clientY);
        if (el && el.closest('.canvas-wrap')) {
          onDrop(s.type, { x: e.clientX, y: e.clientY });
        }
      },
      onPointerCancel: () => {
        start.current = null;
        dragging.current = false;
        setDrag(null);
      },
      onClick: (e: React.MouseEvent) => {
        // Efter ett drag ska klicket INTE också lägga en form i mitten
        if (dragging.current) {
          dragging.current = false;
          e.preventDefault();
          e.stopPropagation();
        }
      },
    }),
    [onDrop],
  );

  return { drag, getChipProps };
}
