// Pappret: ritas i page-space bakom formerna via tldraw-komponenten OnTheCanvas.
// Ligger ALDRIG i dokumentet → kan aldrig läcka in i mermaid-exporten.
import { PAPER } from '@v2e/canvas';

export function PaperBackground() {
  return (
    <div
      style={{
        position: 'absolute',
        left: PAPER.x,
        top: PAPER.y,
        width: PAPER.w,
        height: PAPER.h,
        background: '#ffffff',
        border: '1px solid rgba(0,0,0,0.18)',
        boxShadow: '0 2px 24px rgba(0,0,0,0.10)',
        pointerEvents: 'none',
      }}
    />
  );
}
