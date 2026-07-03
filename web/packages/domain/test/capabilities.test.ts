// Regel 15-grinden för webben: capabilities täcker varje form, och TS-generatorns
// faktiska %%-nycklar är en dokumenterad delmängd av ALL_CARRIER_KEYS (ingen
// odokumenterad nyckel, gapet ärligt listat i NOT_YET_EMITTED_BY_WEB).
import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import {
  ALL_CARRIER_KEYS,
  FEATURES,
  FLAG_CARRIER_KEYS,
  NOT_YET_EMITTED_BY_WEB,
  SHAPE_CAPABILITIES,
  SHAPE_TYPES,
  frameworkText,
} from '../src/index.js';

const srcText = (file: string) =>
  readFileSync(fileURLToPath(new URL(`../src/${file}`, import.meta.url)), 'utf8');

/**
 * Grep:a %%-nycklar ur generator-källkoden. Nyckel-grammatiken har tre former (samma som Swift):
 *  1) `%% <id> nyckel: värde` — nyckeln står före kolonet
 *  2) `%% <id> flagga` — flagg-nycklar utan kolon (FLAG_CARRIER_KEYS)
 *  3) `%% legend <kategori>: text` — nyckeln `legend` står på id-platsen
 */
function emittedCarrierKeys(source: string): Set<string> {
  const keys = new Set<string>();
  for (const snippet of source.match(/%%[^\n`]*/g) ?? []) {
    if (snippet.startsWith('%%{')) continue; // init-direktivet är inte en carrier-nyckel
    for (const m of snippet.matchAll(/([A-Za-z][A-Za-z-]*):/g)) keys.add(m[1]!);
    for (const flag of FLAG_CARRIER_KEYS) {
      if (new RegExp(`\\s${flag}\\s*$`).test(snippet)) keys.add(flag);
    }
    if (/^%%\s+legend\s/.test(snippet)) keys.add('legend');
  }
  return keys;
}

describe('SHAPE_CAPABILITIES', () => {
  it('varje ShapeType har en capability-rad (körtidskoll utöver compile-forcen)', () => {
    for (const t of SHAPE_TYPES) {
      const c = SHAPE_CAPABILITIES[t];
      expect(c, `saknar capability för ${t}`).toBeDefined();
      expect(c.displayName.length).toBeGreaterThan(0);
      expect(c.mermaidForm.length).toBeGreaterThan(0);
    }
  });

  it('app-only-former pekar på en %%-bärare i mermaidForm', () => {
    for (const t of SHAPE_TYPES) {
      const c = SHAPE_CAPABILITIES[t];
      if (c.appOnly) expect(c.mermaidForm).toContain('%%');
    }
  });
});

describe('bijektion generator ↔ ALL_CARRIER_KEYS (regel 15)', () => {
  const emitted = new Set([
    ...emittedCarrierKeys(srcText('generate.ts')),
    ...emittedCarrierKeys(srcText('generate-meta.ts')),
    ...emittedCarrierKeys(srcText('native-state.ts')),
  ]);

  it('varje nyckel generatorn emitterar är dokumenterad i ALL_CARRIER_KEYS', () => {
    for (const k of emitted) {
      expect(ALL_CARRIER_KEYS.has(k), `odokumenterad %%-nyckel i generatorn: ${k}`).toBe(true);
    }
  });

  it('gapet är ärligt: emitterade ∪ NOT_YET_EMITTED_BY_WEB == ALL_CARRIER_KEYS, disjunkt', () => {
    for (const k of emitted) {
      expect(NOT_YET_EMITTED_BY_WEB.has(k), `${k} emitteras men står som ej-emitterad`).toBe(false);
    }
    const union = new Set([...emitted, ...NOT_YET_EMITTED_BY_WEB]);
    expect([...union].sort()).toEqual([...ALL_CARRIER_KEYS].sort());
  });
});

describe('frameworkText', () => {
  const text = frameworkText();

  it('innehåller varje ShapeType-namn', () => {
    for (const t of SHAPE_TYPES) {
      expect(text, `saknar ShapeType ${t}`).toContain(`\`${t}\``);
    }
  });

  it('innehåller varje funktions-namn + rubrikerna', () => {
    for (const f of FEATURES) expect(text).toContain(f.name);
    expect(text).toContain('## NATIVE mermaid-former');
    expect(text).toContain('## EGNA former');
    expect(text).toContain('## Kanter');
    expect(text).toContain('## APP-EGNA funktioner');
  });

  it('state-JSON-only-funktioner flaggas ärligt', () => {
    expect(text).toContain('⚠️ bara i state-blocket');
  });
});
