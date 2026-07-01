// Delbar länk UTAN server: koda diagram-texten i URL:ens hash (#d=...). Unicode-säker base64.
// Räcker för Kims diagram-storlekar; pako-komprimering är en senare uppgradering om diagram blir stora.

function toBase64(text: string): string {
  const bytes = new TextEncoder().encode(text);
  let bin = '';
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin);
}

function fromBase64(b64: string): string {
  const bin = atob(b64);
  const bytes = Uint8Array.from(bin, (c) => c.charCodeAt(0));
  return new TextDecoder().decode(bytes);
}

const HASH_KEY = 'd=';

/** Bygg en delbar länk för given mermaid-text. */
export function encodeShareLink(baseUrl: string, mermaid: string): string {
  const url = new URL(baseUrl);
  url.hash = HASH_KEY + encodeURIComponent(toBase64(mermaid));
  return url.toString();
}

/** Läs ev. delad mermaid ur en URL-hash (#d=...). Returnerar null om ingen/trasig. */
export function decodeShareFromHash(hash: string): string | null {
  const h = hash.startsWith('#') ? hash.slice(1) : hash;
  if (!h.startsWith(HASH_KEY)) return null;
  try {
    return fromBase64(decodeURIComponent(h.slice(HASH_KEY.length)));
  } catch {
    return null;
  }
}
