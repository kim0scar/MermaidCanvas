import type { CanvasStore } from './store.js';
import type { Row, SupabaseLikeClient } from './supabase-client.js';
import {
  PersistenceError,
  type CanvasFile,
  type FileMeta,
  type ShareLink,
  type SharedFile,
  type ShareMode,
  type User,
} from './types.js';

const FILE_COLUMNS = 'id,name,text,updated_at';
const META_COLUMNS = 'id,name,updated_at';

function toMeta(row: Row): FileMeta {
  return { id: String(row['id']), name: String(row['name']), updatedAt: String(row['updated_at']) };
}

function toFile(row: Row): CanvasFile {
  return { ...toMeta(row), text: String(row['text']) };
}

// Moln-storen (kopplas mot riktiga supabase-js i W5). Lagrar HELA .md-texten oförändrad
// i kolumnen `text` — molnet har ALDRIG en egen modell av filen (noll-avvikelse-garantin).
// Vem som får läsa/skriva avgörs av RLS i databasen (sql/schema.sql), inte av koden här.
export class SupabaseCanvasStore implements CanvasStore {
  constructor(private readonly client: SupabaseLikeClient) {}

  private async requireUser(handling: string): Promise<User> {
    const user = await this.currentUser();
    if (!user) throw new PersistenceError(`Du måste vara inloggad för att ${handling}.`);
    return user;
  }

  async listFiles(): Promise<FileMeta[]> {
    const { data, error } = await this.client.from('files').select(META_COLUMNS);
    if (error) throw new PersistenceError(`Kunde inte lista filerna: ${error.message}`);
    return (data ?? []).map(toMeta);
  }

  async loadFile(id: string): Promise<CanvasFile> {
    const { data, error } = await this.client
      .from('files')
      .select(FILE_COLUMNS)
      .eq('id', id)
      .single();
    if (error || !data) {
      throw new PersistenceError(`Filen finns inte eller kunde inte läsas (id: ${id}).`);
    }
    return toFile(data);
  }

  async saveFile(id: string | null, name: string, text: string): Promise<CanvasFile> {
    if (id === null) {
      const user = await this.requireUser('spara en ny fil');
      const { data, error } = await this.client
        .from('files')
        .insert({ owner: user.id, name, text })
        .select(FILE_COLUMNS)
        .single();
      if (error || !data) {
        throw new PersistenceError(`Kunde inte spara filen: ${error?.message ?? 'okänt fel'}`);
      }
      return toFile(data);
    }
    const { data, error } = await this.client
      .from('files')
      .update({ name, text, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select(FILE_COLUMNS)
      .single();
    if (error || !data) {
      throw new PersistenceError(
        `Kunde inte spara filen (id: ${id}): ${error?.message ?? 'filen finns inte'}`,
      );
    }
    return toFile(data);
  }

  async deleteFile(id: string): Promise<void> {
    const { error } = await this.client.from('files').delete().eq('id', id);
    if (error) throw new PersistenceError(`Kunde inte radera filen: ${error.message}`);
  }

  async currentUser(): Promise<User | null> {
    const { data, error } = await this.client.auth.getUser();
    if (error || !data.user) return null; // utloggad
    return { id: data.user.id, email: data.user.email ?? '' };
  }

  async signInWithOtp(email: string): Promise<void> {
    const { error } = await this.client.auth.signInWithOtp({ email });
    if (error) throw new PersistenceError(`Inloggningen misslyckades: ${error.message}`);
  }

  async signOut(): Promise<void> {
    const { error } = await this.client.auth.signOut();
    if (error) throw new PersistenceError(`Utloggningen misslyckades: ${error.message}`);
  }

  async createShareLink(fileId: string, mode: ShareMode): Promise<ShareLink> {
    const user = await this.requireUser('dela en fil');
    const token = crypto.randomUUID();
    const { error } = await this.client
      .from('shares')
      .insert({ token, file_id: fileId, mode, created_by: user.id });
    if (error) throw new PersistenceError(`Kunde inte skapa delnings-länken: ${error.message}`);
    return { token, fileId, mode };
  }

  async openSharedFile(token: string): Promise<SharedFile> {
    const { data, error } = await this.client
      .from('shares')
      .select('token,file_id,mode')
      .eq('token', token)
      .single();
    if (error || !data) throw new PersistenceError('Delnings-länken är ogiltig eller borttagen.');
    const file = await this.loadFile(String(data['file_id']));
    const mode: ShareMode = data['mode'] === 'edit' ? 'edit' : 'read';
    return { file, mode };
  }
}
