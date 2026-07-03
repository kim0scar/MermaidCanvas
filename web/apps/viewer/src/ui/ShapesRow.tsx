import { useState } from 'react';
import type { ShapeType } from '@v2e/domain';
import { ShapeGlyph } from './ShapeGlyph';

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
  ['emoji', 'Emoji'],
];

export function ShapesRow({ onAdd }: { onAdd: (type: ShapeType) => void }) {
  const [tab, setTab] = useState<'grund' | 'verktyg'>('grund');
  const chips = tab === 'grund' ? GRUNDFORMER : VERKTYG;
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
      {chips.map(([type, label]) => (
        <button key={type} className="ios-chip" onClick={() => onAdd(type)} aria-label={label}>
          <ShapeGlyph type={type} />
          <span className="lbl">{label}</span>
        </button>
      ))}
    </div>
  );
}
