import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { extractMermaid, parseCanvasFile } from '../src/index.js';

// FAS 1 — visarens fil-parsning. Bevisar att vi plockar ut EXAKT den renderbara mermaid-kroppen ur en
// riktig MermaidCanvas .md-fil (utan frontmatter, utan state-block) och att råklistrad mermaid också funkar.

// Riktig artefakt från repot (v27-format, med state-block i äldre schema).
const REAL_SAMPLE = readFileSync(
  fileURLToPath(new URL('../../../../arkiv/sample-v27-canvas.md', import.meta.url)),
  'utf8',
);

describe('extractMermaid', () => {
  it('plockar ut mermaid-kroppen ur en full .md (fence) — utan frontmatter/state', () => {
    const body = extractMermaid(REAL_SAMPLE);
    expect(body.startsWith('flowchart TD')).toBe(true);
    expect(body).toContain('module_N0["API"]:::module');
    expect(body).toContain('module_N0 --> module_N1');
    expect(body).not.toContain('mermaidcanvas-state'); // state-blocket ska INTE följa med
    expect(body).not.toContain('title: v27'); // frontmatter ska INTE följa med
    expect(body).not.toContain('```'); // fence-markörerna ska INTE följa med
  });

  it('råklistrad mermaid utan fence returneras oförändrad (trimmad)', () => {
    const raw = 'flowchart TD\n  A --> B\n';
    expect(extractMermaid(raw)).toBe('flowchart TD\n  A --> B');
  });
});

describe('parseCanvasFile', () => {
  it('upptäcker state-blocket i en app-genererad fil (utan att validera schemat)', () => {
    const parsed = parseCanvasFile(REAL_SAMPLE);
    expect(parsed.hasStateBlock).toBe(true);
    expect(parsed.stateJson).toContain('"nodes"'); // v27-schema tolereras
    expect(parsed.mermaid).toContain('flowchart TD');
  });

  it('råklistrad mermaid → inget state-block', () => {
    const parsed = parseCanvasFile('flowchart TD\n  A --> B');
    expect(parsed.hasStateBlock).toBe(false);
    expect(parsed.stateJson).toBeUndefined();
  });
});
