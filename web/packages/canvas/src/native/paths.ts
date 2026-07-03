// SVG-siluetter — exakt port av Swift CanvasShapes.swift-pathmatematiken
// (DiamondShape, ProcessArrowShape, OctagonShape, TriangleShape, CylinderShape).
// RENA d-strängar (ingen React) — delas av rendering + indicator, Node-testbara.
import { DIAMOND_RADIUS_RATIO, OCTAGON_CHAMFER_RATIO, OCTAGON_RADIUS_RATIO, PROCESS_ARROW_RADIUS_RATIO, TRIANGLE_RADIUS_RATIO } from './tokens.js';

interface Pt {
  x: number;
  y: number;
}

const n = (v: number) => +v.toFixed(3);

function unit(a: Pt, b: Pt): Pt {
  const dx = b.x - a.x;
  const dy = b.y - a.y;
  const len = Math.hypot(dx, dy);
  return len > 0.001 ? { x: dx / len, y: dy / len } : { x: 0, y: 0 };
}

function off(p: Pt, v: Pt, amount: number): Pt {
  return { x: p.x + v.x * amount, y: p.y + v.y * amount };
}

/** Polygon med rundade hörn (quadCurve runt varje vertex) — samma mönster som Swift-formerna. */
function roundedPolygonPath(pts: Pt[], radius: number | number[]): string {
  const r = (i: number) => (Array.isArray(radius) ? (radius[i] ?? 0) : radius);
  const parts: string[] = [];
  const count = pts.length;
  for (let i = 0; i < count; i++) {
    const curr = pts[i]!;
    const prev = pts[(i - 1 + count) % count]!;
    const next = pts[(i + 1) % count]!;
    const dIn = unit(prev, curr);
    const dOut = unit(curr, next);
    const start = off(curr, dIn, -r(i));
    const end = off(curr, dOut, r(i));
    parts.push(`${i === 0 ? 'M' : 'L'} ${n(start.x)},${n(start.y)}`);
    parts.push(`Q ${n(curr.x)},${n(curr.y)} ${n(end.x)},${n(end.y)}`);
  }
  return `${parts.join(' ')} Z`;
}

/** Romb — DiamondShape: 4 spetsar, r = min(h×0.10, min(w,h)/4). */
export function diamondPath(w: number, h: number): string {
  const r = Math.min(h * DIAMOND_RADIUS_RATIO, Math.min(w, h) / 4);
  return roundedPolygonPath(
    [
      { x: w / 2, y: 0 },
      { x: w, y: h / 2 },
      { x: w / 2, y: h },
      { x: 0, y: h / 2 },
    ],
    r,
  );
}

/** Processpil — ProcessArrowShape: pentagon, spets 35 % av bredden, rundad spets (v60). */
export function processArrowPath(w: number, h: number): string {
  const tip = w * 0.35;
  const r = Math.min(h * PROCESS_ARROW_RADIUS_RATIO, (w - tip) / 2, h / 2);
  const tipR = Math.min(r, tip * 0.5, h / 3);
  return roundedPolygonPath(
    [
      { x: 0, y: 0 },
      { x: w - tip, y: 0 },
      { x: w, y: h / 2 },
      { x: w - tip, y: h },
      { x: 0, y: h },
    ],
    [r, r, tipR, r, r],
  );
}

/** Oktagon — OctagonShape: fas 0.29×min-sida, hörnradie min(h×0.08, fas×0.8). */
export function octagonPath(w: number, h: number): string {
  const c = Math.min(w, h) * OCTAGON_CHAMFER_RATIO;
  const r = Math.min(h * OCTAGON_RADIUS_RATIO, c * 0.8);
  return roundedPolygonPath(
    [
      { x: c, y: 0 },
      { x: w - c, y: 0 },
      { x: w, y: c },
      { x: w, y: h - c },
      { x: w - c, y: h },
      { x: c, y: h },
      { x: 0, y: h - c },
      { x: 0, y: c },
    ],
    r,
  );
}

/** Liksidig trekant — TriangleShape: centrerad i ramen, r = min(triangelhöjd×0.10, sida/4). */
export function trianglePath(w: number, h: number): string {
  const side = Math.min(w, (h * 2) / Math.sqrt(3));
  const th = (side * Math.sqrt(3)) / 2;
  const cx = w / 2;
  const cy = h / 2;
  const r = Math.min(th * TRIANGLE_RADIUS_RATIO, side / 4);
  return roundedPolygonPath(
    [
      { x: cx, y: cy - th / 2 },
      { x: cx - side / 2, y: cy + th / 2 },
      { x: cx + side / 2, y: cy + th / 2 },
    ],
    r,
  );
}

/** Rundad rektangel som d-sträng (för Path2D-indicators). */
export function roundedRectPath(w: number, h: number, radius: number): string {
  const r = Math.max(0, Math.min(radius, Math.min(w, h) / 2));
  if (r === 0) return `M 0,0 L ${n(w)},0 L ${n(w)},${n(h)} L 0,${n(h)} Z`;
  return (
    `M ${n(r)},0 L ${n(w - r)},0 A ${n(r)},${n(r)} 0 0 1 ${n(w)},${n(r)} ` +
    `L ${n(w)},${n(h - r)} A ${n(r)},${n(r)} 0 0 1 ${n(w - r)},${n(h)} ` +
    `L ${n(r)},${n(h)} A ${n(r)},${n(r)} 0 0 1 0,${n(h - r)} ` +
    `L 0,${n(r)} A ${n(r)},${n(r)} 0 0 1 ${n(r)},0 Z`
  );
}

/** Ellips (cx,cy,rx,ry) som d-sträng. */
export function ellipsePath(cx: number, cy: number, rx: number, ry: number): string {
  return (
    `M ${n(cx - rx)},${n(cy)} A ${n(rx)},${n(ry)} 0 1 0 ${n(cx + rx)},${n(cy)} ` +
    `A ${n(rx)},${n(ry)} 0 1 0 ${n(cx - rx)},${n(cy)} Z`
  );
}

/** Cylinder — CylinderShape: sidor + botten-halvellips (bezier, k=0.5523) + topp-ellips som subpath. */
export function cylinderPath(w: number, h: number): string {
  const capRatio = 0.18;
  const ry = Math.min(h * capRatio, h / 2);
  const k = 0.5523;
  const rx = w / 2;
  const cy = h - ry;
  const body =
    `M 0,${n(ry)} L 0,${n(cy)} ` +
    `C 0,${n(cy + k * ry)} ${n(rx - k * rx)},${n(h)} ${n(rx)},${n(h)} ` +
    `C ${n(rx + k * rx)},${n(h)} ${n(w)},${n(cy + k * ry)} ${n(w)},${n(cy)} ` +
    `L ${n(w)},${n(ry)}`;
  const cap =
    `M 0,${n(ry)} A ${n(rx)},${n(ry)} 0 1 0 ${n(w)},${n(ry)} A ${n(rx)},${n(ry)} 0 1 0 0,${n(ry)} Z`;
  return `${body} ${cap}`;
}
