// mermaid.js-rendering (app-lagret — domänen är renderar-fri). Samma init som konformitetsgrinden
// (securityLevel: "loose", startOnLoad: false) och SAMMA pinnade version (mermaid 11.15.0) så att
// det som visas === det grinden godkänner. Lazy import → mermaid laddas först vid första ritningen.

let initialized = false;
let seq = 0;

export interface RenderResult {
  svg?: string;
  error?: string;
}

/** Rendera mermaid-kod → SVG-sträng. Fångar syntaxfel och returnerar dem (kastar aldrig → aldrig blank). */
export async function renderMermaid(code: string): Promise<RenderResult> {
  try {
    const mermaid = (await import('mermaid')).default;
    if (!initialized) {
      mermaid.initialize({ startOnLoad: false, securityLevel: 'loose' });
      initialized = true;
    }
    const { svg } = await mermaid.render(`v2e-svg-${seq++}`, code);
    return { svg };
  } catch (e) {
    return { error: e instanceof Error ? e.message : String(e) };
  }
}
