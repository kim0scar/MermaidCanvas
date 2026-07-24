import { useState } from 'react';
import type { ShapeType } from '@v2e/domain';
import { ShapeGlyph } from './ShapeGlyph';
import { IconArrowTool } from './icons';
import { useChipDrag } from './useChipDrag';
import { ChipDragGhost } from './ChipDragGhost';

/** Speglar native ToolbarView+ShapesRow: flikar + chips, tap lägger till formen. */
const GRUNDFORMER: Array<[ShapeType, string]> = [
  ['circle', 'Cirkel'],
  ['pill', 'Pill'],
  ['rectangle', 'Rektangel'],
  ['square', 'Kvadrat'],
  ['diamond', 'Romb'],
  ['processArrow', 'Process'],
  ['octagon', 'Oktagon'],
  ['triangle', 'Triangel'],
];

const VERKTYG: Array<[ShapeType, string]> = [
  ['container', 'Grupp'],
  ['table', 'Tabell'],
  ['link', 'Länk'],
  ['cylinder', 'Cylinder'],
  ['phoneFrame', 'iPhone'],
  ['line', 'Linje'],
  ['emoji', 'Emoji'],
];

export function ShapesRow({
  onAdd,
  onAddAt,
  arrowActive,
  onToggleArrow,
}: {
  onAdd: (type: ShapeType) => void;
  onAddAt: (type: ShapeType, client: { x: number; y: number }) => void;
  arrowActive: boolean;
  onToggleArrow: () => void;
}) {
  const [tab, setTab] = useState<'grund' | 'verktyg'>('grund');
  const chips = tab === 'grund' ? GRUNDFORMER : VERKTYG;
  const { drag, getChipProps } = useChipDrag(onAddAt);
  return (
    <div className="ios-subrow">
      <div className="ios-seg" role="tablist">
        <button className={tab === 'grund' ? 'active' : ''} onClick={() => setTab('grund')}>
          Grundformer
        </button>
        <button className={tab === 'verktyg' ? 'active' : ''} onClick={() => setTab('verktyg')}>
          Verktyg
        </button>
      </div>
      <button
        className={arrowActive ? 'ios-chip active' : 'ios-chip'}
        onClick={onToggleArrow}
        aria-label="Rita pil"
        title="Rita pil — dra mellan två former"
      >
        <IconArrowTool />
        <span className="lbl">Pil</span>
      </button>
      {chips.map(([type, label]) => {
        const dragProps = getChipProps(type);
        return (
          <button
            key={type}
            className="ios-chip"
            aria-label={label}
            {...dragProps}
            onClick={(e) => {
              dragProps.onClick(e);
              if (!e.defaultPrevented) onAdd(type);
            }}
          >
            <ShapeGlyph type={type} />
            <span className="lbl">{label}</span>
          </button>
        );
      })}
      <ChipDragGhost drag={drag} />
    </div>
  );
}
