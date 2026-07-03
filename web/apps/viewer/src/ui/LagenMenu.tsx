import type { ReactNode } from 'react';
import {
  IconCode,
  IconCopy,
  IconEye,
  IconNew,
  IconOpen,
  IconSave,
  IconShare,
  IconZoomReset,
} from './icons';

export interface MenuActions {
  onNew: () => void;
  onOpen: () => void;
  onSave: (() => void) | null;
  onShowCode: (() => void) | null;
  onCopyCode: (() => void) | null;
  onShare: (() => void) | null;
  onToggleView: (() => void) | null;
  viewLabel: string;
  onResetZoom: (() => void) | null;
  version: string;
}

function Item({ icon, label, onClick }: { icon: ReactNode; label: string; onClick: () => void }) {
  return (
    <button onClick={onClick}>
      {icon}
      {label}
    </button>
  );
}

/** Speglar native Lägen-menyn: sektioner Skapa / Fil / Kod & export / Visa / Om appen. */
export function LagenMenu({ a, onClose }: { a: MenuActions; onClose: () => void }) {
  const wrap = (fn: (() => void) | null) => (fn ? () => { onClose(); fn(); } : null);
  return (
    <>
      <div className="ios-menu-backdrop" onClick={onClose} />
      <div className="ios-menu" role="menu">
        <div className="version">Visuali2e · webb {a.version}</div>
        <div className="sep" />
        <div className="section">Skapa</div>
        <Item icon={<IconNew />} label="Ny canvas" onClick={wrap(a.onNew)!} />
        <div className="section">Fil</div>
        <Item icon={<IconOpen />} label="Öppna fil" onClick={wrap(a.onOpen)!} />
        {a.onSave && <Item icon={<IconSave />} label="Spara .md" onClick={wrap(a.onSave)!} />}
        <div className="section">Kod &amp; export</div>
        {a.onShowCode && <Item icon={<IconCode />} label="Visa kod" onClick={wrap(a.onShowCode)!} />}
        {a.onCopyCode && <Item icon={<IconCopy />} label="Kopiera kod" onClick={wrap(a.onCopyCode)!} />}
        {a.onShare && <Item icon={<IconShare />} label="Dela länk" onClick={wrap(a.onShare)!} />}
        <div className="section">Visa</div>
        {a.onToggleView && <Item icon={<IconEye />} label={a.viewLabel} onClick={wrap(a.onToggleView)!} />}
        {a.onResetZoom && (
          <Item icon={<IconZoomReset />} label="Återställ zoom" onClick={wrap(a.onResetZoom)!} />
        )}
      </div>
    </>
  );
}
