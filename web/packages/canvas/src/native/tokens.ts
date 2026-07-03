// Design-tokens — port av Swift DesignTokens.swift (hörnradier som ratio + stroke).
// EN källa så rendering och indicator inte glider isär.
import type { ShapeType } from '@v2e/domain';

export const STROKE_WIDTH = 1.5;
export const SHADOW = 'drop-shadow(0 1px 3px rgba(0,0,0,0.06))';

export const RECTANGLE_RADIUS_RATIO = 0.10;
export const SQUARE_RADIUS_RATIO = 0.06;
export const DIAMOND_RADIUS_RATIO = 0.10;
export const PROCESS_ARROW_RADIUS_RATIO = 0.30;
export const CONTAINER_RADIUS_RATIO = 0.08;
export const TABLE_RADIUS_RATIO = 0.075;
export const OCTAGON_RADIUS_RATIO = 0.08;
export const OCTAGON_CHAMFER_RATIO = 0.29;
export const PHONE_FRAME_RADIUS_RATIO = 0.16;
export const TRIANGLE_RADIUS_RATIO = 0.10;

/** Port av DesignTokens.Shape.cornerRadius(for:height:) — square/phoneFrame följer min-sidan. */
export function cornerRadius(type: ShapeType, w: number, h: number): number {
  switch (type) {
    case 'rectangle': return h * RECTANGLE_RADIUS_RATIO;
    case 'container': return h * CONTAINER_RADIUS_RATIO;
    case 'table': return h * TABLE_RADIUS_RATIO;
    case 'square': return Math.min(w, h) * SQUARE_RADIUS_RATIO;
    case 'diamond': return h * DIAMOND_RADIUS_RATIO;
    case 'processArrow': return h * PROCESS_ARROW_RADIUS_RATIO;
    case 'octagon': return h * OCTAGON_RADIUS_RATIO;
    case 'phoneFrame': return Math.min(w, h) * PHONE_FRAME_RADIUS_RATIO;
    case 'triangle': return h * TRIANGLE_RADIUS_RATIO;
    case 'cylinder': return h * 0.10;
    case 'pill': return h / 2;
    case 'circle': return h / 2;
    case 'line': return 0;
    case 'arrow': return 0;
    case 'link': return 0;
    case 'emoji': return h * 0.16;
  }
}
