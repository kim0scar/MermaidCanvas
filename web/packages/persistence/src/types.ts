// Typer för persistence-lagret (W5-grunden). Filens .md-TEXT är kanonisk —
// den lagras och returneras alltid oförändrad, byte för byte (noll-avvikelse).

export interface FileMeta {
  id: string;
  name: string;
  /** ISO 8601 */
  updatedAt: string;
}

export interface CanvasFile extends FileMeta {
  /** HELA .md-texten, exakt som den sparades. */
  text: string;
}

export interface User {
  id: string;
  email: string;
}

export type ShareMode = 'read' | 'edit';

export interface ShareLink {
  token: string;
  fileId: string;
  mode: ShareMode;
}

export interface SharedFile {
  file: CanvasFile;
  mode: ShareMode;
}

/** Alla fel ur en CanvasStore kastas som detta — med begripligt svenskt meddelande. */
export class PersistenceError extends Error {
  override name = 'PersistenceError';
}
