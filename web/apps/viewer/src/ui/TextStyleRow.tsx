import type { TextAlignMode, TextStyle } from '@v2e/domain';

/** Speglar native FormattingBar + TextSizeGallery: 5 nivåer i (skalad) verklig storlek,
    fet/kursiv/understruken, justering. Appliceras på markerade former. */
export interface TextStylePatch {
  textStyle?: TextStyle;
  bold?: boolean;
  italic?: boolean;
  underline?: boolean;
  textAlignment?: TextAlignMode;
  hasBullets?: boolean;
  hasNumberedList?: boolean;
  indentLevel?: number;
}

export interface TextStyleState {
  textStyle: TextStyle | null;
  bold: boolean;
  italic: boolean;
  underline: boolean;
  textAlignment: TextAlignMode | null;
  hasBullets: boolean;
  hasNumberedList: boolean;
  indentLevel: number;
}

const SIZES: Array<{ style: TextStyle; label: string; px: number; weight: number }> = [
  { style: 'jatte', label: 'XL', px: 24, weight: 700 },
  { style: 'r1', label: 'R1', px: 20, weight: 700 },
  { style: 'r2', label: 'R2', px: 17, weight: 600 },
  { style: 'r3', label: 'R3', px: 15, weight: 500 },
  { style: 'body', label: 'Aa', px: 13, weight: 400 },
];

const ALIGNMENTS: Array<{ align: TextAlignMode; glyph: string; name: string }> = [
  { align: 'leading', glyph: '⇤', name: 'Vänster' },
  { align: 'center', glyph: '≡', name: 'Centrerad' },
  { align: 'trailing', glyph: '⇥', name: 'Höger' },
];

export function TextStyleRow({
  state,
  onApply,
}: {
  state: TextStyleState;
  onApply: (patch: TextStylePatch) => void;
}) {
  return (
    <div className="ios-subrow">
      {SIZES.map((s) => (
        <button
          key={s.style}
          className={state.textStyle === s.style ? 'ios-stylebtn active' : 'ios-stylebtn'}
          style={{ fontSize: s.px, fontWeight: s.weight }}
          onClick={() => onApply({ textStyle: s.style })}
          aria-label={`Textstorlek ${s.label}`}
        >
          {s.label}
        </button>
      ))}
      <div className="ios-divider" />
      <button
        className={state.bold ? 'ios-stylebtn active' : 'ios-stylebtn'}
        style={{ fontWeight: 700 }}
        onClick={() => onApply({ bold: !state.bold })}
        aria-label="Fet"
      >
        F
      </button>
      <button
        className={state.italic ? 'ios-stylebtn active' : 'ios-stylebtn'}
        style={{ fontStyle: 'italic' }}
        onClick={() => onApply({ italic: !state.italic })}
        aria-label="Kursiv"
      >
        K
      </button>
      <button
        className={state.underline ? 'ios-stylebtn active' : 'ios-stylebtn'}
        style={{ textDecoration: 'underline' }}
        onClick={() => onApply({ underline: !state.underline })}
        aria-label="Understruken"
      >
        U
      </button>
      <div className="ios-divider" />
      {ALIGNMENTS.map((a) => (
        <button
          key={a.align}
          className={state.textAlignment === a.align ? 'ios-stylebtn active' : 'ios-stylebtn'}
          onClick={() => onApply({ textAlignment: a.align })}
          aria-label={`Justering ${a.name}`}
          title={a.name}
        >
          {a.glyph}
        </button>
      ))}
      <div className="ios-divider" />
      <button
        className={state.hasBullets ? 'ios-stylebtn active' : 'ios-stylebtn'}
        onClick={() => onApply({ hasBullets: !state.hasBullets })}
        aria-label="Punktlista"
        title="Punktlista"
      >
        •
      </button>
      <button
        className={state.hasNumberedList ? 'ios-stylebtn active' : 'ios-stylebtn'}
        onClick={() => onApply({ hasNumberedList: !state.hasNumberedList })}
        aria-label="Numrerad lista"
        title="Numrerad lista"
      >
        1.
      </button>
      <button
        className="ios-stylebtn"
        onClick={() => onApply({ indentLevel: Math.max(0, state.indentLevel - 1) })}
        aria-label="Minska indrag"
        title="Minska indrag"
      >
        «
      </button>
      <button
        className="ios-stylebtn"
        onClick={() => onApply({ indentLevel: Math.min(3, state.indentLevel + 1) })}
        aria-label="Öka indrag"
        title="Öka indrag"
      >
        »
      </button>
    </div>
  );
}
