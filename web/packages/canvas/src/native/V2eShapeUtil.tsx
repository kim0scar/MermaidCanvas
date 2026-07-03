// Custom tldraw-form som renderar domän-noderna native-troget (iOS-appens utseende).
// Speglar GeoShapeUtil:s text-redigeringslösning: canEdit + RichTextLabel vid redigering,
// annars statisk V2eLabel (bullets/indrag/understrykning som native).
/* eslint-disable react-hooks/rules-of-hooks */
import {
  BaseBoxShapeUtil,
  Ellipse2d,
  HTMLContainer,
  Polygon2d,
  Rectangle2d,
  RichTextLabel,
  SVGContainer,
  Vec,
  resizeBox,
  toRichText,
  useValue,
  type Geometry2d,
  type RecordProps,
  type TLResizeInfo,
  type TLShape,
} from 'tldraw';
import { BASE_SIZES } from '../sizes.js';
import { richToPlain } from '../richtext.js';
import { effectiveColors } from './colors.js';
import { SHAPE_BODY, shapeIndicatorPath, shapeShadow } from './geometry.js';
import { OCTAGON_CHAMFER_RATIO } from './tokens.js';
import {
  FONT_STACK,
  TEXT_STYLE_FONT,
  V2eContainerHeader,
  V2eEmojiGlyph,
  V2eLabel,
  effectiveWeight,
} from './text.js';
import { V2E_SHAPE_TYPE, v2eShapeProps, type V2eShapeProps } from './shape-props.js';

export type V2eShape = TLShape<'v2e-shape'>;

const RICH_TEXT_ALIGN = { leading: 'start', center: 'center', trailing: 'end' } as const;

export class V2eShapeUtil extends BaseBoxShapeUtil<V2eShape> {
  static override type = V2E_SHAPE_TYPE;
  static override props: RecordProps<V2eShape> = v2eShapeProps;

  override getDefaultProps(): V2eShapeProps {
    return {
      w: BASE_SIZES.rectangle.w,
      h: BASE_SIZES.rectangle.h,
      shapeType: 'rectangle',
      category: 'ui',
      richText: toRichText(''),
      showLabel: true,
      sizeMultiplier: 1,
      textStyle: 'body',
      bold: false,
      italic: false,
      underline: false,
      textAlignment: 'center',
      hasBullets: false,
      hasNumberedList: false,
      indentLevel: 0,
      colorPackId: '',
      color: '',
      strokeColor: '',
      tableRows: 0,
      tableCols: 0,
      tableCells: [],
      linkNumber: 0,
      skillNumber: 0,
      isSubskill: false,
    };
  }

  override canEdit(): boolean {
    return true;
  }

  override getText(shape: V2eShape): string {
    return richToPlain(shape.props.richText);
  }

  /** Riktig geometri för formerna med egna siluetter (pil-fästen + hit-test följer formen). */
  override getGeometry(shape: V2eShape): Geometry2d {
    const { w, h, shapeType } = shape.props;
    switch (shapeType) {
      case 'circle':
        return new Ellipse2d({ width: w, height: h, isFilled: true });
      case 'diamond':
        return new Polygon2d({
          points: [new Vec(w / 2, 0), new Vec(w, h / 2), new Vec(w / 2, h), new Vec(0, h / 2)],
          isFilled: true,
        });
      case 'triangle': {
        const side = Math.min(w, (h * 2) / Math.sqrt(3));
        const th = (side * Math.sqrt(3)) / 2;
        return new Polygon2d({
          points: [
            new Vec(w / 2, h / 2 - th / 2),
            new Vec(w / 2 - side / 2, h / 2 + th / 2),
            new Vec(w / 2 + side / 2, h / 2 + th / 2),
          ],
          isFilled: true,
        });
      }
      case 'octagon': {
        const c = Math.min(w, h) * OCTAGON_CHAMFER_RATIO;
        return new Polygon2d({
          points: [
            new Vec(c, 0), new Vec(w - c, 0), new Vec(w, c), new Vec(w, h - c),
            new Vec(w - c, h), new Vec(c, h), new Vec(0, h - c), new Vec(0, c),
          ],
          isFilled: true,
        });
      }
      default:
        return new Rectangle2d({ width: w, height: h, isFilled: true });
    }
  }

  /** Storleksändring: resizeBox + uppdatera font-skalnings-hinten vid uniform skalning (som native). */
  override onResize(shape: V2eShape, info: TLResizeInfo<V2eShape>) {
    const next = resizeBox(shape, info);
    const base = BASE_SIZES[shape.props.shapeType];
    const wm = (next.props?.w ?? shape.props.w) / base.w;
    const hm = (next.props?.h ?? shape.props.h) / base.h;
    if (Math.abs(wm - hm) < 1e-6) {
      return { ...next, props: { ...next.props, sizeMultiplier: wm } };
    }
    return next;
  }

  override component(shape: V2eShape) {
    const props = shape.props;
    const isEditing = useValue(
      'v2e-editing',
      () => this.editor.getEditingShapeId() === shape.id,
      [this.editor, shape.id],
    );
    const isOnlySelected = useValue(
      'v2e-only-selected',
      () => this.editor.getOnlySelectedShapeId() === shape.id,
      [this.editor, shape.id],
    );
    const colors = effectiveColors({
      category: props.category,
      colorPackId: props.colorPackId || undefined,
      color: props.color || undefined,
      strokeColor: props.strokeColor || undefined,
    });
    const font = TEXT_STYLE_FONT[props.textStyle];
    const clipId = `v2e_${shape.id.replace(/[^a-zA-Z0-9_-]/g, '_')}`;
    const isContainerLike = props.shapeType === 'container' || props.shapeType === 'phoneFrame';

    return (
      <>
        <SVGContainer style={{ filter: shapeShadow(props.shapeType) }}>
          {SHAPE_BODY[props.shapeType]({ shape: props, colors, clipId })}
        </SVGContainer>
        <HTMLContainer
          style={{ width: props.w, height: props.h, pointerEvents: isEditing ? 'all' : 'none' }}
        >
          {props.shapeType === 'emoji' && !isEditing && <V2eEmojiGlyph shape={props} />}
          {props.shapeType === 'container' && !isEditing && <V2eContainerHeader shape={props} />}
          {!isContainerLike && props.shapeType !== 'emoji' && !isEditing && (
            <V2eLabel shape={props} colors={colors} />
          )}
          {isEditing && (
            <div
              style={{
                position: 'absolute',
                inset: 0,
                fontWeight: effectiveWeight(props.textStyle, props.bold),
                fontStyle: props.italic ? 'italic' : 'normal',
                textDecoration: props.underline ? 'underline' : 'none',
              }}
            >
              <RichTextLabel
                shapeId={shape.id}
                type={V2E_SHAPE_TYPE}
                richText={props.richText}
                labelColor={colors.text}
                fontFamily={FONT_STACK}
                fontSize={font.size * props.sizeMultiplier}
                lineHeight={1.25}
                padding={8}
                textAlign={RICH_TEXT_ALIGN[props.textAlignment]}
                verticalAlign="middle"
                isSelected={isOnlySelected}
                wrap
              />
            </div>
          )}
        </HTMLContainer>
      </>
    );
  }

  override getIndicatorPath(shape: V2eShape): Path2D {
    return new Path2D(shapeIndicatorPath(shape.props));
  }
}

/** Ges till <Tldraw shapeUtils={V2E_SHAPE_UTILS}>. */
export const V2E_SHAPE_UTILS = [V2eShapeUtil];
