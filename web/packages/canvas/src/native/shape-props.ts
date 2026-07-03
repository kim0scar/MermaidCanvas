// v2e-shape: props-schema + record-typ. REN modul (ingen React) så mapping.ts
// förblir Node-testbar. Props bär BARA det som behövs för rendering — resten av
// domän-noden bor i meta.domain (round-trip-garantin, jämför-före-skriv).
//
// Sentineler ('' / 0 / []) i stället för optionella props: tldraw-props måste vara
// JSON-kompletta. '' = fältet saknas i domän-noden.
import {
  SHAPE_CATEGORIES,
  SHAPE_TYPES,
  TEXT_STYLES,
  type ShapeCategory,
  type ShapeType,
  type TextAlignMode,
  type TextStyle,
} from '@v2e/domain';
import { richTextValidator, type TLRichText } from '@tldraw/tlschema';
import { T } from '@tldraw/validate';

export const V2E_SHAPE_TYPE = 'v2e-shape' as const;

export interface V2eShapeProps {
  w: number;
  h: number;
  shapeType: ShapeType;
  category: ShapeCategory;
  richText: TLRichText;
  showLabel: boolean;
  /** Render-hint för fontskala (Swift: fontSize × sizeMultiplier). Läses ALDRIG tillbaka till domänen — w/h är sanningen. */
  sizeMultiplier: number;
  textStyle: TextStyle;
  bold: boolean;
  italic: boolean;
  underline: boolean;
  textAlignment: TextAlignMode;
  hasBullets: boolean;
  hasNumberedList: boolean;
  indentLevel: number;
  /** '' = inget paket. */
  colorPackId: string;
  /** '' = ingen egen fyllning (hex '#rrggbb' annars). */
  color: string;
  /** '' = ingen egen ram. */
  strokeColor: string;
  /** 0 = ej satt (tabell ritar då 3×3 som native). */
  tableRows: number;
  tableCols: number;
  tableCells: string[][];
  /** 0 = ej satt. */
  linkNumber: number;
  /** 0 = ej satt (container-rubrik "Skill N · namn"). */
  skillNumber: number;
  /** Härledd ur childOfContainerId (container-rubrik "Subskill"). Läses aldrig tillbaka. */
  isSubskill: boolean;
}

// Registrera v2e-shape i tldraws typ-union (5.x-mönstret) — då fungerar
// BaseBoxShapeUtil, RichTextLabel och editor.updateShape med full typning.
declare module '@tldraw/tlschema' {
  interface TLGlobalShapePropsMap {
    'v2e-shape': V2eShapeProps;
  }
}

/** T-validatorer — tldraws schema-grind för varje prop. */
export const v2eShapeProps = {
  w: T.nonZeroNumber,
  h: T.nonZeroNumber,
  shapeType: T.literalEnum(...SHAPE_TYPES),
  category: T.literalEnum(...SHAPE_CATEGORIES),
  richText: richTextValidator,
  showLabel: T.boolean,
  sizeMultiplier: T.number,
  textStyle: T.literalEnum(...TEXT_STYLES),
  bold: T.boolean,
  italic: T.boolean,
  underline: T.boolean,
  textAlignment: T.literalEnum('leading', 'center', 'trailing'),
  hasBullets: T.boolean,
  hasNumberedList: T.boolean,
  indentLevel: T.number,
  colorPackId: T.string,
  color: T.string,
  strokeColor: T.string,
  tableRows: T.number,
  tableCols: T.number,
  tableCells: T.arrayOf(T.arrayOf(T.string)),
  linkNumber: T.number,
  skillNumber: T.number,
  isSubskill: T.boolean,
};
