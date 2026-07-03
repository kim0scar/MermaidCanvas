// Dela upp AI-svarstext i text- och ```mermaid-segment. Oavslutade block (mitt i
// en stream) räknas som mermaid så kodkortet kan växa medan svaret skrivs.

export interface ChatSegment {
  kind: 'text' | 'mermaid';
  content: string;
}

const FENCE = /```mermaid[^\n]*\n([\s\S]*?)(?:\n?```|$)/g;

export function splitMermaidBlocks(text: string): ChatSegment[] {
  const segments: ChatSegment[] = [];
  let last = 0;
  FENCE.lastIndex = 0;
  for (let m = FENCE.exec(text); m !== null; m = FENCE.exec(text)) {
    const before = text.slice(last, m.index);
    if (before.trim()) segments.push({ kind: 'text', content: before.trim() });
    segments.push({ kind: 'mermaid', content: (m[1] ?? '').trim() });
    last = m.index + m[0].length;
  }
  const rest = text.slice(last);
  if (rest.trim()) segments.push({ kind: 'text', content: rest.trim() });
  return segments;
}
