import type { CanvasStore } from './store.js';
import {
  PersistenceError,
  type CanvasFile,
  type FileMeta,
  type ShareLink,
  type SharedFile,
  type ShareMode,
  type User,
} from './types.js';

/** Minsta delmängd av window.localStorage som behövs (testbar utan DOM). */
export interface KeyValueStorage {
  getItem(key: string): string | null;
  setItem(key: string, value: string): void;
  removeItem(key: string): void;
}

const STORAGE_KEY = 'v2e.files.v1';

/** Ren minnes-storage — default när ingen localStorage injiceras. */
export function memoryStorage(): KeyValueStorage {
  const map = new Map<string, string>();
  return {
    getItem: (key) => map.get(key) ?? null,
    setItem: (key, value) => {
      map.set(key, value);
    },
    removeItem: (key) => {
      map.delete(key);
    },
  };
}

// Lokalt-först-storen: fungerar idag utan konto, och blir offline-fallbacken i W5.
// Allt ligger under EN nyckel som JSON — texten round-trippar byte-identiskt genom JSON-strängen.
export class LocalCanvasStore implements CanvasStore {
  private readonly storage: KeyValueStorage;

  constructor(storage: KeyValueStorage = memoryStorage()) {
    this.storage = storage;
  }

  private readAll(): CanvasFile[] {
    const raw = this.storage.getItem(STORAGE_KEY);
    if (raw === null) return [];
    try {
      return JSON.parse(raw) as CanvasFile[];
    } catch {
      throw new PersistenceError('Det lokala fillagret är skadat och kunde inte läsas.');
    }
  }

  private writeAll(files: CanvasFile[]): void {
    this.storage.setItem(STORAGE_KEY, JSON.stringify(files));
  }

  async listFiles(): Promise<FileMeta[]> {
    return this.readAll().map(({ id, name, updatedAt }) => ({ id, name, updatedAt }));
  }

  async loadFile(id: string): Promise<CanvasFile> {
    const file = this.readAll().find((f) => f.id === id);
    if (!file) throw new PersistenceError(`Filen finns inte (id: ${id}).`);
    return { ...file };
  }

  async saveFile(id: string | null, name: string, text: string): Promise<CanvasFile> {
    const files = this.readAll();
    const updatedAt = new Date().toISOString();
    if (id === null) {
      const file: CanvasFile = { id: crypto.randomUUID(), name, text, updatedAt };
      files.push(file);
      this.writeAll(files);
      return { ...file };
    }
    const file = files.find((f) => f.id === id);
    if (!file) throw new PersistenceError(`Filen finns inte (id: ${id}).`);
    file.name = name;
    file.text = text;
    file.updatedAt = updatedAt;
    this.writeAll(files);
    return { ...file };
  }

  async deleteFile(id: string): Promise<void> {
    this.writeAll(this.readAll().filter((f) => f.id !== id));
  }

  // Konto och delning finns bara i moln-läget (W5) — lokalt svarar vi ärligt.
  async currentUser(): Promise<User | null> {
    return null;
  }

  async signInWithOtp(_email: string): Promise<void> {
    throw new PersistenceError('Inloggning kräver moln-läget (kommer i W5).');
  }

  async signOut(): Promise<void> {
    // Ingen inloggning lokalt — utloggning är en ofarlig no-op.
  }

  async createShareLink(_fileId: string, _mode: ShareMode): Promise<ShareLink> {
    throw new PersistenceError('Delnings-länkar kräver moln-läget (kommer i W5).');
  }

  async openSharedFile(_token: string): Promise<SharedFile> {
    throw new PersistenceError('Delnings-länkar kräver moln-läget (kommer i W5).');
  }
}
