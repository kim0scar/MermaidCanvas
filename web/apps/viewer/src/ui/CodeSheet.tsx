import { useState } from 'react';
import { IconClose, IconCopy } from './icons';

/** Speglar native "Visa kod": hela .md-källan + kopiera. */
export function CodeSheet({ source, onClose }: { source: string; onClose: () => void }) {
  const [copied, setCopied] = useState(false);
  const copy = async () => {
    try {
      await navigator.clipboard.writeText(source);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 1500);
    } catch {
      // urklipp nekad — markera texten manuellt
    }
  };
  return (
    <div className="code-sheet">
      <div className="code-sheet-bar">
        <b>Mermaid-kod</b>
        <span className="spacer" />
        <button className="ios-iconbtn" onClick={() => void copy()} aria-label="Kopiera kod">
          {copied ? '✓' : <IconCopy />}
        </button>
        <button className="ios-iconbtn" onClick={onClose} aria-label="Stäng">
          <IconClose />
        </button>
      </div>
      <pre>{source}</pre>
    </div>
  );
}
