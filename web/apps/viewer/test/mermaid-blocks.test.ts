import { describe, expect, it } from 'vitest';
import { splitMermaidBlocks } from '../src/copilot/mermaid-blocks';

describe('splitMermaidBlocks', () => {
  it('ren text → ett text-segment', () => {
    expect(splitMermaidBlocks('Hej! Vad vill du rita?')).toEqual([
      { kind: 'text', content: 'Hej! Vad vill du rita?' },
    ]);
  });

  it('text + mermaid-block + text', () => {
    const text = 'Här är flödet:\n```mermaid\nflowchart TD\n    a["Start"] --> b["Slut"]\n```\nSäg till om något ska ändras.';
    expect(splitMermaidBlocks(text)).toEqual([
      { kind: 'text', content: 'Här är flödet:' },
      { kind: 'mermaid', content: 'flowchart TD\n    a["Start"] --> b["Slut"]' },
      { kind: 'text', content: 'Säg till om något ska ändras.' },
    ]);
  });

  it('två block i samma svar', () => {
    const text = '```mermaid\nA\n```\nmellan\n```mermaid\nB\n```';
    expect(splitMermaidBlocks(text)).toEqual([
      { kind: 'mermaid', content: 'A' },
      { kind: 'text', content: 'mellan' },
      { kind: 'mermaid', content: 'B' },
    ]);
  });

  it('oavslutat block (mitt i stream) → mermaid till slutet', () => {
    const text = 'Såhär:\n```mermaid\nflowchart TD\n    a["Sta';
    expect(splitMermaidBlocks(text)).toEqual([
      { kind: 'text', content: 'Såhär:' },
      { kind: 'mermaid', content: 'flowchart TD\n    a["Sta' },
    ]);
  });

  it('annat kodspråk lämnas som text', () => {
    const text = 'Kod:\n```js\nconsole.log(1)\n```';
    expect(splitMermaidBlocks(text)).toEqual([{ kind: 'text', content: text.trim() }]);
  });
});
