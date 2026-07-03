import type { CanvasFile, FileMeta, ShareLink, SharedFile, ShareMode, User } from './types.js';

// Adapter-interfacet UI:t pratar med. Idag: LocalCanvasStore (lokalt-först, offline-fallback).
// W5: SupabaseCanvasStore med riktiga supabase-js bakom SAMMA interface — UI:t märker ingen skillnad.
export interface CanvasStore {
  /** Metadata för alla filer (utan text — lätt lista). */
  listFiles(): Promise<FileMeta[]>;
  /** Hela filen. Kastar PersistenceError om id saknas. */
  loadFile(id: string): Promise<CanvasFile>;
  /** id = null → ny fil. Returnerar den sparade filen (med id). Texten lagras oförändrad. */
  saveFile(id: string | null, name: string, text: string): Promise<CanvasFile>;
  /** Idempotent — att radera ett redan borttaget id är inget fel. */
  deleteFile(id: string): Promise<void>;

  currentUser(): Promise<User | null>;
  signInWithOtp(email: string): Promise<void>;
  signOut(): Promise<void>;

  createShareLink(fileId: string, mode: ShareMode): Promise<ShareLink>;
  openSharedFile(token: string): Promise<SharedFile>;
}
