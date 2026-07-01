// Ren text ↔ tldraw richText (ProseMirror-JSON). Egen extraherare (ingen Editor-instans krävs)
// så mappningen kan enhetstestas i Node och beter sig identiskt i appen.
import { toRichText, type TLRichText } from '@tldraw/tlschema';

export function plainToRich(text: string): TLRichText {
  return toRichText(text);
}

interface RichNode {
  type?: string;
  text?: string;
  content?: RichNode[];
}

/** Plocka ut ren text ur richText-dokumentet: paragrafer → rader, text-noder → innehåll. */
export function richToPlain(rich: TLRichText | undefined): string {
  if (!rich) return '';
  const root = rich as unknown as RichNode;
  const paragraphs = root.content ?? [];
  return paragraphs.map(collectText).join('\n');
}

function collectText(node: RichNode): string {
  if (node.text !== undefined) return node.text;
  return (node.content ?? []).map(collectText).join('');
}
