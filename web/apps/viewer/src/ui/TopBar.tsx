import type { ReactNode } from 'react';
import {
  IconMenu,
  IconPalette,
  IconRedo,
  IconShapes,
  IconSparkle,
  IconTextStyle,
  IconTrash,
  IconUndo,
} from './icons';

export type SubRow = 'shapes' | 'colors' | 'text' | null;

/** Speglar native ToolbarView-primärraden: Former · Färger · Textstil · … · zoom · Lägen. */
export function TopBar({
  subRow,
  onToggleRow,
  aiOpen,
  onToggleAi,
  onUndo,
  onRedo,
  onDelete,
  zoomPercent,
  onSave,
  saveLabel,
  menu,
  menuOpen,
  onToggleMenu,
}: {
  subRow: SubRow;
  onToggleRow: (row: Exclude<SubRow, null>) => void;
  aiOpen: boolean;
  onToggleAi: () => void;
  onUndo: (() => void) | null;
  onRedo: (() => void) | null;
  onDelete: (() => void) | null;
  zoomPercent: number | null;
  onSave: (() => void) | null;
  saveLabel: string;
  menu: ReactNode;
  menuOpen: boolean;
  onToggleMenu: () => void;
}) {
  const rowBtn = (row: Exclude<SubRow, null>, label: string, icon: ReactNode) => (
    <button
      className={subRow === row ? 'ios-iconbtn active' : 'ios-iconbtn'}
      onClick={() => onToggleRow(row)}
      aria-label={label}
      title={label}
    >
      {icon}
    </button>
  );

  return (
    <div className="ios-topbar">
      {rowBtn('shapes', 'Former', <IconShapes />)}
      {rowBtn('colors', 'Färger', <IconPalette />)}
      {rowBtn('text', 'Textstil', <IconTextStyle />)}
      <button
        className={aiOpen ? 'ios-iconbtn active' : 'ios-iconbtn'}
        onClick={onToggleAi}
        aria-label="AI-hjälp"
        title="AI-hjälp"
      >
        <IconSparkle />
      </button>
      {onDelete && (
        <button className="ios-iconbtn" onClick={onDelete} aria-label="Radera markerade" title="Radera">
          <IconTrash />
        </button>
      )}
      <span className="spacer" />
      {onUndo && (
        <button className="ios-iconbtn" onClick={onUndo} aria-label="Ångra" title="Ångra">
          <IconUndo />
        </button>
      )}
      {onRedo && (
        <button className="ios-iconbtn" onClick={onRedo} aria-label="Gör om" title="Gör om">
          <IconRedo />
        </button>
      )}
      {zoomPercent !== null && <span className="ios-zoombadge">{zoomPercent}%</span>}
      {onSave && (
        <button className="ios-savebtn" onClick={onSave}>
          {saveLabel}
        </button>
      )}
      <div className="ios-menu-wrap">
        <button
          className={menuOpen ? 'ios-iconbtn active' : 'ios-iconbtn'}
          onClick={onToggleMenu}
          aria-label="Lägen"
          title="Lägen"
        >
          <IconMenu />
        </button>
        {menuOpen && menu}
      </div>
    </div>
  );
}
