// Port av Swift MermaidAutoLayout.swift — lagrad auto-layout för rå mermaid utan
// `%% pos:`-rader. Kanternas riktning ger nivåer; flowchart-riktningen ger axeln.
// REN TS, 0 beroenden.

import type { Point } from './model.js';

export type FlowDirection = 'td' | 'lr' | 'bt' | 'rl';

/** Läser riktningen från `flowchart XX` / `graph XX`. Default: TD. */
export function flowDirectionIn(block: string): FlowDirection {
  for (const rawLine of block.split('\n')) {
    const line = rawLine.trim();
    if (line === '') continue;
    const lower = line.toLowerCase();
    if (!lower.startsWith('flowchart') && !lower.startsWith('graph')) continue;
    const parts = line.split(' ').filter((p) => p.length > 0);
    if (parts.length < 2) return 'td';
    switch (parts[1]!.toUpperCase()) {
      case 'LR': return 'lr';
      case 'BT': return 'bt';
      case 'RL': return 'rl';
      default: return 'td'; // TD, TB och allt okänt
    }
  }
  return 'td';
}

/**
 * En position per nod-id. Noder utan kanter hamnar i nivå 0.
 * Cykler hanteras genom att nivå-stegningen begränsas till antal noder.
 */
export function autoLayoutPositions(
  nodeIds: string[],
  edges: ReadonlyArray<{ from: string; to: string }>,
  direction: FlowDirection,
): Map<string, Point> {
  const result = new Map<string, Point>();
  if (nodeIds.length === 0) return result;

  // Longest-path-nivåer: B ligger alltid minst en nivå efter A för A-->B.
  const layer = new Map<string, number>();
  for (const id of nodeIds) layer.set(id, 0);
  const known = new Set(nodeIds);
  const relevant = edges.filter((e) => known.has(e.from) && known.has(e.to) && e.from !== e.to);
  // Itererar max nodeIds.length gånger — skyddar mot cykler (A-->B-->A).
  for (let iter = 0; iter < nodeIds.length; iter++) {
    let changed = false;
    for (const e of relevant) {
      const want = layer.get(e.from)! + 1;
      if (layer.get(e.to)! < want && want < nodeIds.length) {
        layer.set(e.to, want);
        changed = true;
      }
    }
    if (!changed) break;
  }

  // Gruppera per nivå, behåll deklarationsordningen inom nivån.
  const byLayer = new Map<number, string[]>();
  for (const id of nodeIds) {
    const lvl = layer.get(id)!;
    const list = byLayer.get(lvl) ?? [];
    list.push(id);
    byLayer.set(lvl, list);
  }
  const maxLayer = Math.max(...byLayer.keys());

  // Avstånd valda för bas-former 120×80 pt med marginal.
  const mainGap = 170;   // mellan nivåer (flödesriktningen)
  const crossGap = 170;  // mellan syskon inom en nivå
  const origin: Point = { x: 200, y: 160 };

  for (const [lvl, ids] of byLayer) {
    // Spegla nivån för BT/RL så flödet går åt rätt håll.
    const effectiveLevel = direction === 'bt' || direction === 'rl' ? maxLayer - lvl : lvl;
    ids.forEach((id, i) => {
      // Centrera syskonen kring origin på tväraxeln.
      const crossOffset = (i - (ids.length - 1) / 2) * crossGap;
      if (direction === 'td' || direction === 'bt') {
        result.set(id, { x: origin.x + crossOffset, y: origin.y + effectiveLevel * mainGap });
      } else {
        result.set(id, { x: origin.x + effectiveLevel * mainGap, y: origin.y + crossOffset });
      }
    });
  }
  return result;
}
