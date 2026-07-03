import { describe, it, expect, beforeEach } from 'vitest';
import { PersistenceError, type CanvasStore } from '../src/index.js';

// Elak text: frontmatter, CRLF, tabb, emoji med ZWJ, %%-metadata, backslash, citattecken, state-block.
// Round-trippen ska vara BYTE-identisk — texten är kanonisk (noll-avvikelse-garantin).
export const NASTY_TEXT =
  '---\ntitle: prov\n---\n\n```mermaid\nflowchart TD\n  A["Ä Ö å 👩‍👩‍👧‍👦 \\"citat\\""] --> B\n%% shape-type: A oktagon\n```\r\n\t<!-- mermaidcanvas-state {"shapes":[]} -->\nslut\\n\n';

// SAMMA kontrakts-svit körs mot BÅDA stores (lokal + supabase-mock) så de aldrig glider isär.
export function runCanvasStoreContract(
  name: string,
  makeStore: () => CanvasStore | Promise<CanvasStore>,
): void {
  describe(`${name} — CanvasStore-kontraktet`, () => {
    let store: CanvasStore;

    beforeEach(async () => {
      store = await makeStore();
    });

    it('spara ny fil → får id och syns i listan', async () => {
      const saved = await store.saveFile(null, 'Flöde A', 'flowchart TD\n  A --> B\n');
      expect(saved.id).toBeTruthy();
      expect(saved.name).toBe('Flöde A');
      const list = await store.listFiles();
      expect(list.map((f) => f.id)).toContain(saved.id);
    });

    it('texten round-trippar byte-identiskt (elaka tecken)', async () => {
      const saved = await store.saveFile(null, 'Elak', NASTY_TEXT);
      const loaded = await store.loadFile(saved.id);
      expect(loaded.text).toBe(NASTY_TEXT);
      expect(loaded.text.length).toBe(NASTY_TEXT.length);
    });

    it('saveFile(id) uppdaterar samma fil — ingen dubblett', async () => {
      const first = await store.saveFile(null, 'Namn 1', 'v1');
      const second = await store.saveFile(first.id, 'Namn 2', 'v2');
      expect(second.id).toBe(first.id);
      const loaded = await store.loadFile(first.id);
      expect(loaded.name).toBe('Namn 2');
      expect(loaded.text).toBe('v2');
      const list = await store.listFiles();
      expect(list.filter((f) => f.id === first.id)).toHaveLength(1);
    });

    it('flera filer — rätt text per id', async () => {
      const a = await store.saveFile(null, 'A', 'text-A');
      const b = await store.saveFile(null, 'B', 'text-B');
      expect((await store.loadFile(a.id)).text).toBe('text-A');
      expect((await store.loadFile(b.id)).text).toBe('text-B');
      expect(await store.listFiles()).toHaveLength(2);
    });

    it('deleteFile tar bort filen — och är idempotent', async () => {
      const saved = await store.saveFile(null, 'Bort', 'x');
      await store.deleteFile(saved.id);
      expect(await store.listFiles()).toHaveLength(0);
      await expect(store.loadFile(saved.id)).rejects.toBeInstanceOf(PersistenceError);
      await expect(store.deleteFile(saved.id)).resolves.toBeUndefined();
    });

    it('loadFile på okänt id kastar PersistenceError', async () => {
      await expect(store.loadFile('finns-inte')).rejects.toBeInstanceOf(PersistenceError);
    });

    it('saveFile på okänt id kastar PersistenceError', async () => {
      await expect(store.saveFile('finns-inte', 'x', 'y')).rejects.toBeInstanceOf(
        PersistenceError,
      );
    });
  });
}
