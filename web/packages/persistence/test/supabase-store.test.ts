import { describe, it, expect } from 'vitest';
import { SupabaseCanvasStore, PersistenceError } from '../src/index.js';
import { FakeSupabase } from './fake-supabase.js';
import { runCanvasStoreContract, NASTY_TEXT } from './store-contract.js';

function makeSignedIn(): { fake: FakeSupabase; store: SupabaseCanvasStore } {
  const fake = new FakeSupabase();
  fake.user = { id: 'kim-id', email: 'kim@example.com' };
  return { fake, store: new SupabaseCanvasStore(fake) };
}

// Gemensamma kontraktet (samma svit som LocalCanvasStore kör).
runCanvasStoreContract('SupabaseCanvasStore (mock-klient)', () => makeSignedIn().store);

describe('SupabaseCanvasStore — rätt anrop mot klienten', () => {
  it('listFiles: select på files UTAN text-kolumnen (lätt lista)', async () => {
    const { fake, store } = makeSignedIn();
    await store.listFiles();
    expect(fake.calls).toHaveLength(1);
    expect(fake.calls[0]).toMatchObject({
      table: 'files',
      op: 'select',
      columns: 'id,name,updated_at',
    });
  });

  it('loadFile: select + eq(id) + single', async () => {
    const { fake, store } = makeSignedIn();
    const saved = await store.saveFile(null, 'A', 'x');
    fake.calls.length = 0;
    await store.loadFile(saved.id);
    expect(fake.calls[0]).toMatchObject({
      table: 'files',
      op: 'select',
      columns: 'id,name,text,updated_at',
      single: true,
    });
    expect(fake.calls[0]!.eq).toEqual([['id', saved.id]]);
  });

  it('saveFile(null): insert i files med owner = inloggad användare', async () => {
    const { fake, store } = makeSignedIn();
    const saved = await store.saveFile(null, 'Ny', NASTY_TEXT);
    expect(fake.calls[0]).toMatchObject({ table: 'files', op: 'insert' });
    expect(fake.calls[0]!.values).toMatchObject({ owner: 'kim-id', name: 'Ny', text: NASTY_TEXT });
    expect(saved.text).toBe(NASTY_TEXT);
  });

  it('saveFile(null) utan inloggning → begripligt fel, inget insert skickas', async () => {
    const store = new SupabaseCanvasStore(new FakeSupabase());
    await expect(store.saveFile(null, 'x', 'y')).rejects.toThrow(/inloggad/);
  });

  it('saveFile(id): update + eq(id)', async () => {
    const { fake, store } = makeSignedIn();
    const saved = await store.saveFile(null, 'A', 'v1');
    fake.calls.length = 0;
    await store.saveFile(saved.id, 'A2', 'v2');
    expect(fake.calls[0]).toMatchObject({ table: 'files', op: 'update' });
    expect(fake.calls[0]!.values).toMatchObject({ name: 'A2', text: 'v2' });
    expect(fake.calls[0]!.eq).toEqual([['id', saved.id]]);
  });

  it('deleteFile: delete + eq(id)', async () => {
    const { fake, store } = makeSignedIn();
    const saved = await store.saveFile(null, 'A', 'x');
    fake.calls.length = 0;
    await store.deleteFile(saved.id);
    expect(fake.calls[0]).toMatchObject({ table: 'files', op: 'delete' });
    expect(fake.calls[0]!.eq).toEqual([['id', saved.id]]);
  });

  it('fel från klienten propageras som PersistenceError med leverantörens meddelande', async () => {
    const { fake, store } = makeSignedIn();
    fake.failNextWith('nätverket nere');
    const err: unknown = await store.listFiles().catch((e: unknown) => e);
    expect(err).toBeInstanceOf(PersistenceError);
    expect((err as Error).message).toContain('nätverket nere');
  });
});

describe('SupabaseCanvasStore — auth', () => {
  it('signInWithOtp → currentUser speglar läget → signOut nollar', async () => {
    const store = new SupabaseCanvasStore(new FakeSupabase());
    expect(await store.currentUser()).toBeNull();
    await store.signInWithOtp('kim@example.com');
    expect(await store.currentUser()).toEqual({
      id: 'user-kim@example.com',
      email: 'kim@example.com',
    });
    await store.signOut();
    expect(await store.currentUser()).toBeNull();
  });

  it('misslyckad inloggning kastar med leverantörens meddelande', async () => {
    const fake = new FakeSupabase();
    const store = new SupabaseCanvasStore(fake);
    fake.failNextWith('otp rate limit');
    const err: unknown = await store.signInWithOtp('kim@example.com').catch((e: unknown) => e);
    expect(err).toBeInstanceOf(PersistenceError);
    expect((err as Error).message).toContain('otp rate limit');
  });
});

describe('SupabaseCanvasStore — delning', () => {
  it('createShareLink: insert i shares med token/file_id/mode/created_by', async () => {
    const { fake, store } = makeSignedIn();
    const file = await store.saveFile(null, 'Delad', 'innehåll');
    fake.calls.length = 0;
    const link = await store.createShareLink(file.id, 'edit');
    expect(link.fileId).toBe(file.id);
    expect(link.mode).toBe('edit');
    expect(link.token.length).toBeGreaterThanOrEqual(16);
    expect(fake.calls[0]).toMatchObject({ table: 'shares', op: 'insert' });
    expect(fake.calls[0]!.values).toMatchObject({
      token: link.token,
      file_id: file.id,
      mode: 'edit',
      created_by: 'kim-id',
    });
  });

  it('openSharedFile: token → shares-lookup → filen, byte-identisk text', async () => {
    const { fake, store } = makeSignedIn();
    const file = await store.saveFile(null, 'Delad', NASTY_TEXT);
    const link = await store.createShareLink(file.id, 'read');
    fake.calls.length = 0;
    const opened = await store.openSharedFile(link.token);
    expect(opened.mode).toBe('read');
    expect(opened.file.id).toBe(file.id);
    expect(opened.file.text).toBe(NASTY_TEXT);
    expect(fake.calls[0]).toMatchObject({ table: 'shares', op: 'select', single: true });
    expect(fake.calls[0]!.eq).toEqual([['token', link.token]]);
    expect(fake.calls[1]).toMatchObject({ table: 'files', op: 'select', single: true });
  });

  it('okänd token → begripligt fel', async () => {
    const { store } = makeSignedIn();
    const err: unknown = await store.openSharedFile('fel-token').catch((e: unknown) => e);
    expect(err).toBeInstanceOf(PersistenceError);
    expect((err as Error).message).toMatch(/ogiltig/i);
  });

  it('delning kräver inloggning', async () => {
    const store = new SupabaseCanvasStore(new FakeSupabase());
    await expect(store.createShareLink('f1', 'read')).rejects.toThrow(/inloggad/);
  });
});
