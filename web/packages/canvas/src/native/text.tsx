// Etikett-rendering — port av Swift TextStyle.swift + ShapeView+Style.swift
// (formattedLabel, effectiveWeight, text-inset, container-rubrik).
import type { ShapeType, TextStyle } from '@v2e/domain';
import { richToPlain } from '../richtext.js';
import type { V2eShapeProps } from './shape-props.js';
import type { ColorSet } from './colors.js';

/** Port av TextStyle.fontSize/fontWeight — 5 tydliga steg (1.5). */
export const TEXT_STYLE_FONT = {
  jatte: { size: 40, weight: 700 },
  r1: { size: 30, weight: 700 },
  r2: { size: 24, weight: 600 },
  r3: { size: 18, weight: 500 },
  body: { size: 14, weight: 400 },
} as const satisfies Record<TextStyle, { size: number; weight: number }>;

/** Systemfont, rundad där den finns (native använder .rounded). */
export const FONT_STACK =
  "ui-rounded, -apple-system, BlinkMacSystemFont, 'SF Pro Rounded', 'Segoe UI', Roboto, sans-serif";

/** Port av effectiveWeight: fet-toggle = en notch tyngre än rubriknivåns egen vikt. */
export function effectiveWeight(style: TextStyle, bold: boolean): number {
  const base = TEXT_STYLE_FONT[style].weight;
  if (!bold) return base;
  return base >= 700 ? 800 : 700;
}

/** Port av formattedLabel: bullets/numrering + indrag (2 mellanslag per nivå). */
export function formatLabel(
  label: string,
  hasBullets: boolean,
  hasNumberedList: boolean,
  indentLevel: number,
): string {
  const indent = '  '.repeat(Math.max(0, indentLevel));
  const lines = label.split('\n');
  if (hasNumberedList) return lines.map((l, i) => `${indent}${i + 1}. ${l}`).join('\n');
  if (hasBullets) return lines.map((l) => `${indent}• ${l}`).join('\n');
  if (indentLevel > 0) return lines.map((l) => `${indent}${l}`).join('\n');
  return label;
}

/** Port av textHorizontalInset — former som smalnar av får extra sido-marginal. */
export function textHorizontalInset(type: ShapeType, w: number): number {
  switch (type) {
    case 'triangle': return 18;
    case 'diamond': return 22;
    case 'circle': return Math.max(10, w * 0.15);
    default: return 8;
  }
}

/** Port av textVerticalOffset — trekanten är bred bara nedtill. */
export function textVerticalOffset(type: ShapeType, h: number): number {
  return type === 'triangle' ? h * 0.20 : 0;
}

const ALIGN_CSS = { leading: 'left', center: 'center', trailing: 'right' } as const;

/** Statisk etikett (icke-redigeringsläget) — native-trogen typografi. */
export function V2eLabel({ shape, colors }: { shape: V2eShapeProps; colors: ColorSet }) {
  if (!shape.showLabel) return null;
  const label = richToPlain(shape.richText);
  if (label === '') return null;
  const font = TEXT_STYLE_FONT[shape.textStyle];
  const inset = textHorizontalInset(shape.shapeType, shape.w);
  const offsetY = textVerticalOffset(shape.shapeType, shape.h);
  return (
    <div
      style={{
        position: 'absolute',
        inset: 0,
        display: 'flex',
        alignItems: 'center',
        pointerEvents: 'none',
        transform: offsetY !== 0 ? `translateY(${offsetY}px)` : undefined,
      }}
    >
      <div
        style={{
          width: '100%',
          paddingLeft: inset,
          paddingRight: inset,
          fontFamily: FONT_STACK,
          fontSize: font.size * shape.sizeMultiplier,
          fontWeight: effectiveWeight(shape.textStyle, shape.bold),
          fontStyle: shape.italic ? 'italic' : 'normal',
          textDecoration: shape.underline ? 'underline' : 'none',
          textAlign: ALIGN_CSS[shape.textAlignment],
          color: colors.text,
          lineHeight: 1.25,
          whiteSpace: 'pre-wrap',
          overflowWrap: 'break-word',
        }}
      >
        {formatLabel(label, shape.hasBullets, shape.hasNumberedList, shape.indentLevel)}
      </div>
    </div>
  );
}

/** Port av containerHeaderTitle — skill-containrar visar kedjenumret. */
export function containerHeaderTitle(shape: V2eShapeProps): string {
  const label = richToPlain(shape.richText);
  const name =
    label === ''
      ? 'Grupp'
      : formatLabel(label, shape.hasBullets, shape.hasNumberedList, shape.indentLevel);
  if (shape.category !== 'skill') return name;
  const kind = shape.isSubskill ? 'Subskill' : 'Skill';
  if (shape.skillNumber > 0) return `${kind} ${shape.skillNumber} · ${name}`;
  return kind === 'Subskill' ? `Subskill · ${name}` : name;
}

export const CONTAINER_HEADER_HEIGHT = 28;

/** Container-rubrikrad (HTML ovanpå SVG-headern) — vit, semibold, centrerad, skill-markör. */
export function V2eContainerHeader({ shape }: { shape: V2eShapeProps }) {
  const fontScale = Math.min(shape.sizeMultiplier, 1.4);
  return (
    <div
      style={{
        position: 'absolute',
        top: 0,
        left: 0,
        width: shape.w,
        height: CONTAINER_HEADER_HEIGHT,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 5,
        pointerEvents: 'none',
        color: '#ffffff',
        fontFamily: FONT_STACK,
        fontSize: 13 * fontScale,
        fontWeight: 600,
        whiteSpace: 'nowrap',
        overflow: 'hidden',
        textOverflow: 'ellipsis',
        paddingLeft: 10,
        paddingRight: 10,
      }}
    >
      {shape.category === 'skill' && (
        <span style={{ fontSize: 9 * fontScale, opacity: 0.85 }}>⬢</span>
      )}
      <span style={{ overflow: 'hidden', textOverflow: 'ellipsis' }}>
        {containerHeaderTitle(shape)}
      </span>
    </div>
  );
}

/** v1.0 naken emoji — bara glyfen, stor, fyller formen. */
export function V2eEmojiGlyph({ shape }: { shape: V2eShapeProps }) {
  const label = richToPlain(shape.richText);
  return (
    <div
      style={{
        position: 'absolute',
        inset: 0,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontSize: shape.h * 0.78,
        lineHeight: 1,
        pointerEvents: 'none',
      }}
    >
      {label === '' ? '🙂' : label}
    </div>
  );
}
