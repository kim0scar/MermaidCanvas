// Markeringsläget som chromet behöver — egen liten modul UTAN tldraw-import,
// så App:s huvudbundle inte drar in rit-ytan (den lazy-laddas).
import type { TextAlignMode, TextStyle } from '@v2e/domain';

export interface SelectionState {
  count: number;
  textStyle: TextStyle | null;
  bold: boolean;
  italic: boolean;
  underline: boolean;
  textAlignment: TextAlignMode | null;
  hasBullets: boolean;
  hasNumberedList: boolean;
  indentLevel: number;
  /** Egen fyllningsfärg (hex) eller '' = ingen (använder paket/kategori). */
  color: string;
  /** Egen ramfärg (hex) eller '' = ingen. */
  strokeColor: string;
}

export const EMPTY_SELECTION: SelectionState = {
  count: 0,
  textStyle: null,
  bold: false,
  italic: false,
  underline: false,
  textAlignment: null,
  hasBullets: false,
  hasNumberedList: false,
  indentLevel: 0,
  color: '',
  strokeColor: '',
};
