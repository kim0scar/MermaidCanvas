import { describe, it, expect } from 'vitest';
import { LocalCanvasStore, memoryStorage, PersistenceError } from '../src/index.js';
import { runCanvasStoreContract, NASTY_TEXT } from './store-contract.js';

// Gemensamma kontraktet (samma svit som SupabaseCanvasStore kör).
runCanvasStoreContract('LocalCanvasStore', () => new LocalCanvasStore());

describe('LocalCanvasStore — lokalt-specifikt', () => {
  it('två instanser över samma storage ser samma filer (byte-identiskt)', async () => {
    const storage = memoryStorage();
    const a = new LocalCanvasStore(storage);
    const saved = await a.saveFile(null, 'Delad', NASTY_TEXT);
    const b = new LocalCanvasStore(storage);
    expect((await b.loadFile(saved.id)).text).toBe(NASTY_TEXT);
  });

  it('inget konto lokalt: currentUser är null, signOut ofarlig', async () => {
    const store = new LocalCanvasStore();
    expect(await store.currentUser()).toBeNull();
    await expect(store.signOut()).resolves.toBeUndefined();
  });

  it('inloggning och delning kräver moln-läget — begripliga fel', async () => {
    const store = new LocalCanvasStore();
    await expect(store.signInWithOtp('kim@example.com')).rejects.toThrow(/moln/i);
    await expect(store.createShareLink('x', 'read')).rejects.toThrow(/moln/i);
    await expect(store.openSharedFile('token')).rejects.toThrow(/moln/i);
  });

  it('skadad storage ger begripligt fel — inte en krasch', async () => {
    const storage = memoryStorage();
    storage.setItem('v2e.files.v1', '{trasig json');
    const store = new LocalCanvasStore(storage);
    await expect(store.listFiles()).rejects.toBeInstanceOf(PersistenceError);
  });
});
