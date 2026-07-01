// Basstorlekar per form-typ — exakt port av Swift ShapeGeometry.typeBaseWidth/Height.
// `satisfies Record<ShapeType, …>` = kompilerings-tvingad täckning (ny form utan rad kompilerar ej),
// samma grind-princip som Swifts uttömmande switch.
import type { ShapeNode, ShapeType } from '@v2e/domain';

export interface BaseSize {
  w: number;
  h: number;
}

export const BASE_SIZES = {
  circle: { w: 120, h: 80 },
  rectangle: { w: 120, h: 80 },
  diamond: { w: 120, h: 80 },
  table: { w: 120, h: 80 },
  link: { w: 120, h: 80 },
  pill: { w: 138, h: 74 },
  line: { w: 120, h: 80 },
  arrow: { w: 120, h: 80 },
  square: { w: 80, h: 80 },
  processArrow: { w: 110, h: 80 },
  container: { w: 280, h: 200 },
  octagon: { w: 80, h: 80 },
  phoneFrame: { w: 180, h: 391 },
  triangle: { w: 88, h: 80 },
  cylinder: { w: 100, h: 90 },
  emoji: { w: 64, h: 64 },
} as const satisfies Record<ShapeType, BaseSize>;

/** Effektiv skalning — port av Swift `effectiveWidth/Height` (widthMultiplier ?? sizeMultiplier). */
export function effectiveSize(shape: ShapeNode): BaseSize {
  const base = BASE_SIZES[shape.type];
  return {
    w: base.w * (shape.widthMultiplier ?? shape.sizeMultiplier),
    h: base.h * (shape.heightMultiplier ?? shape.sizeMultiplier),
  };
}
