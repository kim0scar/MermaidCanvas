// Synlig navigering i RITA-läget: zooma ut / in / passa in allt (som iOS fit-to-screen).
import type { Editor } from 'tldraw';

export function ZoomControls({ editor }: { editor: Editor }) {
  return (
    <div className="zoom-ctrl">
      <button onClick={() => editor.zoomOut()} aria-label="Zooma ut">−</button>
      <button onClick={() => editor.zoomIn()} aria-label="Zooma in">+</button>
      <button
        onClick={() => editor.zoomToFit({ animation: { duration: 200 } })}
        aria-label="Passa in allt"
      >
        ⤢
      </button>
    </div>
  );
}
