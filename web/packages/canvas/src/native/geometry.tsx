// SVG-kroppar per ShapeType — port av Swift ShapeRenderer.swift + ShapeBackgrounds.swift.
// Uttömmande `satisfies Record<ShapeType, …>` = ny form utan rendering kompilerar inte.
// Skugga följer Swift-sanningen: bara "solida" grundformer har skugga.
import type { ReactElement } from 'react';
import type { ShapeType } from '@v2e/domain';
import { CATEGORY_COLORS, type ColorSet } from './colors.js';
import {
  cylinderPath,
  diamondPath,
  ellipsePath,
  octagonPath,
  processArrowPath,
  roundedRectPath,
  trianglePath,
} from './paths.js';
import {
  CONTAINER_RADIUS_RATIO,
  PHONE_FRAME_RADIUS_RATIO,
  RECTANGLE_RADIUS_RATIO,
  SHADOW,
  SQUARE_RADIUS_RATIO,
  STROKE_WIDTH,
  cornerRadius,
} from './tokens.js';
import { CONTAINER_HEADER_HEIGHT } from './text.js';
import type { V2eShapeProps } from './shape-props.js';

export interface BodyProps {
  shape: V2eShapeProps;
  colors: ColorSet;
  /** Unikt id-prefix för clipPaths (per shape-instans). */
  clipId: string;
}

type BodyRenderer = (p: BodyProps) => ReactElement | null;

/** Fylld siluett + ram — gemensamt mönster för path-formerna. */
function filled(d: string, colors: ColorSet): ReactElement {
  return <path d={d} fill={colors.fill} stroke={colors.stroke} strokeWidth={STROKE_WIDTH} />;
}

function roundedRect(shape: V2eShapeProps, colors: ColorSet, rx: number): ReactElement {
  return (
    <rect
      width={shape.w}
      height={shape.h}
      rx={rx}
      ry={rx}
      fill={colors.fill}
      stroke={colors.stroke}
      strokeWidth={STROKE_WIDTH}
    />
  );
}

export const SHAPE_BODY = {
  circle: ({ shape, colors }) => (
    <ellipse
      cx={shape.w / 2}
      cy={shape.h / 2}
      rx={shape.w / 2}
      ry={shape.h / 2}
      fill={colors.fill}
      stroke={colors.stroke}
      strokeWidth={STROKE_WIDTH}
    />
  ),
  rectangle: ({ shape, colors }) => roundedRect(shape, colors, shape.h * RECTANGLE_RADIUS_RATIO),
  square: ({ shape, colors }) =>
    roundedRect(shape, colors, Math.min(shape.w, shape.h) * SQUARE_RADIUS_RATIO),
  pill: ({ shape, colors }) => roundedRect(shape, colors, Math.min(shape.w, shape.h) / 2),
  diamond: ({ shape, colors }) => filled(diamondPath(shape.w, shape.h), colors),
  processArrow: ({ shape, colors }) => filled(processArrowPath(shape.w, shape.h), colors),
  octagon: ({ shape, colors }) => filled(octagonPath(shape.w, shape.h), colors),
  triangle: ({ shape, colors }) => filled(trianglePath(shape.w, shape.h), colors),
  cylinder: ({ shape, colors }) => filled(cylinderPath(shape.w, shape.h), colors),

  // v60 Lucidchart-stil: solid header-rad i kategori-ramfärgen + ljus kropp + tunn ram.
  container: ({ shape, colors, clipId }) => {
    const { w, h, category } = shape;
    const r = h * CONTAINER_RADIUS_RATIO;
    const catStroke = CATEGORY_COLORS[category].stroke;
    const isSkill = category === 'skill';
    return (
      <g>
        <clipPath id={clipId}>
          <rect width={w} height={h} rx={r} ry={r} />
        </clipPath>
        <g clipPath={`url(#${clipId})`}>
          <rect width={w} height={CONTAINER_HEADER_HEIGHT} fill={catStroke} />
          <rect
            y={CONTAINER_HEADER_HEIGHT}
            width={w}
            height={Math.max(0, h - CONTAINER_HEADER_HEIGHT)}
            fill={colors.fill}
            opacity={0.04}
          />
        </g>
        <rect
          width={w}
          height={h}
          rx={r}
          ry={r}
          fill="none"
          stroke={catStroke}
          strokeOpacity={isSkill ? 0.8 : 0.6}
          strokeWidth={isSkill ? 2 : 1.5}
        />
      </g>
    );
  },

  // v67: mörk bezel + ljus skärm + dynamic island.
  phoneFrame: ({ shape, colors }) => {
    const { w, h } = shape;
    const r = Math.min(w, h) * PHONE_FRAME_RADIUS_RATIO;
    const inset = Math.max(4, w * 0.045);
    const screenR = Math.max(2, r - inset);
    const islandH = Math.max(8, h * 0.028);
    return (
      <g>
        <rect width={w} height={h} rx={r} ry={r} fill={colors.stroke} />
        <rect
          x={inset}
          y={inset}
          width={w - inset * 2}
          height={h - inset * 2}
          rx={screenR}
          ry={screenR}
          fill={colors.fill}
        />
        <rect
          x={w / 2 - (w * 0.34) / 2}
          y={inset + h * 0.035 - islandH / 2}
          width={w * 0.34}
          height={islandH}
          rx={islandH / 2}
          fill={colors.stroke}
        />
      </g>
    );
  },

  // Grid av rader/kolumner + cellinnehåll (TableShapeBackground).
  table: ({ shape, colors }) => {
    const { w, h } = shape;
    const rows = Math.max(1, shape.tableRows || 3);
    const cols = Math.max(1, shape.tableCols || 3);
    const cellW = w / cols;
    const cellH = h / rows;
    const lines: string[] = [];
    for (let r = 1; r < rows; r++) lines.push(`M 0,${cellH * r} L ${w},${cellH * r}`);
    for (let c = 1; c < cols; c++) lines.push(`M ${cellW * c},0 L ${cellW * c},${h}`);
    const fontSize = Math.max(8, Math.min(cellH * 0.4, 12));
    return (
      <g>
        <rect width={w} height={h} rx={6} ry={6} fill={colors.fill} fillOpacity={0.18} />
        <rect width={w} height={h} rx={6} ry={6} fill="none" stroke={colors.stroke} strokeWidth={STROKE_WIDTH} />
        <path d={lines.join(' ')} stroke={colors.stroke} strokeOpacity={0.5} strokeWidth={1} fill="none" />
        {shape.tableCells.flatMap((row, ri) =>
          row.map((text, ci) =>
            text === '' || ri >= rows || ci >= cols ? null : (
              <text
                key={`${ri}-${ci}`}
                x={cellW * (ci + 0.5)}
                y={cellH * (ri + 0.5)}
                textAnchor="middle"
                dominantBaseline="central"
                fontSize={fontSize}
                fill={colors.stroke}
              >
                {text}
              </text>
            ),
          ),
        )}
      </g>
    );
  },

  // Länk-bubbla (JumpLinkShapeBackground): cirkel + kedje-glyf + nummer i ramfärg.
  link: ({ shape, colors }) => {
    const { w, h } = shape;
    const r = Math.min(w, h) / 2;
    const cx = w / 2;
    const cy = h / 2;
    return (
      <g>
        <circle cx={cx} cy={cy} r={r} fill={colors.fill} stroke={colors.stroke} strokeWidth={STROKE_WIDTH} />
        <g stroke={colors.stroke} strokeWidth={1.8} fill="none">
          <circle cx={cx - 3} cy={cy - r * 0.32} r={3.4} />
          <circle cx={cx + 3} cy={cy - r * 0.32} r={3.4} />
        </g>
        <text
          x={cx}
          y={cy + r * 0.28}
          textAnchor="middle"
          dominantBaseline="central"
          fontSize={13}
          fontWeight={800}
          fill={colors.stroke}
        >
          {shape.linkNumber || 0}
        </text>
      </g>
    );
  },

  // Lös linje / pil — enkel streck-glyf genom mitten (identiteten bor i meta.domain).
  line: ({ shape, colors }) => (
    <line x1={0} y1={shape.h / 2} x2={shape.w} y2={shape.h / 2} stroke={colors.stroke} strokeWidth={2} />
  ),
  arrow: ({ shape, colors }) => {
    const y = shape.h / 2;
    const tip = Math.min(12, shape.w * 0.15);
    return (
      <g stroke={colors.stroke} strokeWidth={2} fill="none">
        <line x1={0} y1={y} x2={shape.w} y2={y} />
        <path d={`M ${shape.w - tip},${y - tip * 0.6} L ${shape.w},${y} L ${shape.w - tip},${y + tip * 0.6}`} />
      </g>
    );
  },

  // v1.0: naken emoji — glyfen ritas i text-lagret, ingen SVG-kropp.
  emoji: () => null,
} as const satisfies Record<ShapeType, BodyRenderer>;

/** Skugga per form — Swift-sanningen: bara solida grundformer har skugga. */
export function shapeShadow(type: ShapeType): string | undefined {
  switch (type) {
    case 'circle':
    case 'rectangle':
    case 'square':
    case 'pill':
    case 'diamond':
    case 'processArrow':
    case 'octagon':
    case 'triangle':
    case 'cylinder':
      return SHADOW;
    default:
      return undefined;
  }
}

/** Form-trogen indicator-siluett som d-sträng (matas till Path2D i getIndicatorPath). */
export function shapeIndicatorPath(shape: V2eShapeProps): string {
  const { w, h, shapeType } = shape;
  switch (shapeType) {
    case 'circle':
      return ellipsePath(w / 2, h / 2, w / 2, h / 2);
    case 'diamond':
      return diamondPath(w, h);
    case 'processArrow':
      return processArrowPath(w, h);
    case 'octagon':
      return octagonPath(w, h);
    case 'triangle':
      return trianglePath(w, h);
    case 'cylinder':
      return cylinderPath(w, h);
    case 'link': {
      const r = Math.min(w, h) / 2;
      return ellipsePath(w / 2, h / 2, r, r);
    }
    default:
      return roundedRectPath(w, h, cornerRadius(shapeType, w, h));
  }
}
