// Native-trogen rendering: färger/typografi/geometri + toolbar-handlingar för v2e-shape.
// OBS: själva V2eShapeUtil (värde-importerar tldraw, ~2 MB) exporteras via subpath
// '@v2e/canvas/shape-util' så visarens huvud-bundle förblir slimmad (tldraw lazy-laddas).
export * from './colors.js';
export * from './tokens.js';
export * from './paths.js';
export * from './shape-props.js';
export * from './text.js';
export * from './geometry.js';
export * from './add-shape.js';
export * from './camera.js';
export type { V2eShape } from './V2eShapeUtil.js';
