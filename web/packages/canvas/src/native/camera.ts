// Kamerans regler: fast 4000×4000-papper (som native CanvasModel.contentSize),
// zoom max 4.0, 'contain' = kan aldrig panorera ut i tomrummet.
import type { TLCameraOptions } from 'tldraw';

export const PAPER = { x: 0, y: 0, w: 4000, h: 4000 };

export const CAMERA_OPTIONS: Partial<TLCameraOptions> = {
  zoomSteps: [0.1, 0.25, 0.5, 1, 2, 4],
  constraints: {
    bounds: PAPER,
    padding: { x: 24, y: 24 },
    origin: { x: 0.5, y: 0.5 },
    initialZoom: 'fit-max-100',
    baseZoom: 'default',
    behavior: 'contain',
  },
};
