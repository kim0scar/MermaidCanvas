# HANDOVER v73 — beslutslogg + nuläge

*Datum: 2026-06-10. Version: v73 (deployad till Kims iPhone — väntar på Kims öppning/verifiering).*
*Läs denna + `UX_PERSONA_AUDIT.md` + `ROADMAP.md` (v73-blocket) för full bild.*

## 0. Det stora sammanhanget — Kims målbild blev tydligare

Kim delade ChatGPT-konvot **"!MERMAID BETA"** (`~/Downloads/ChatGPT-!MERMAID BETA.md`).
Målbilden i en mening: **mermaid-koden ÄR skillen** — en revisionsbar process där huvudagenten
bara orkestrerar, subagent-PAR med olika verktyg löser samma uppgift blinda för varandra,
gap-analys + konsensus-grind avgör vad som är fakta, diffar utreds i verifieringsvågor,
och de ~5 % som inte kan bevisas flaggas till Kim i stället för att gissas. Determinism
genom PROCESS, inte genom bättre prompts. Kim ska kunna validera allt visuellt i appen.

## 1. Vad som gjordes (en session, 2026-06-09→10)

1. **Full UX-audit:** jag testade appen själv via idb (skill-resan steg för steg), sedan
   alla 6 personas på två parallella simulatorer. Resultat: `UX_PERSONA_AUDIT.md` —
   22 unika fynd, inga krascher, 8 av 14 v50.6-fynd bekräftat åtgärdade.
2. **11 app-fixar samma session** (alla sim-verifierade, detaljer i ROADMAP v73):
   viktigast UX-110 (mermaid/state-JSON-inkonsistens för container-medlemskap — protokollbrott
   mot round-trip-regeln) och UX-105 (canvas-former osynliga i a11y-trädet).
3. **Skill 1 v2 + Skill 2 byggda** enligt redundans-arkitekturen. Ritade specs i iCloud
   (`mfp-site-intelligence.md` v2, `mfp-sortiment.md`) + SKILL.md-filer synkade.
   Mönstret låst i `SKILL-KEDJA-KONTRAKT.md` ("Redundans-mönstret v73").

## 2. Vägval — och varför

| Vägval | Beslut | Varför |
|---|---|---|
| Discovery: hur många vägar? | 4 (meny/sök/sitemap/API) | Okänd terräng — olika vägar kan inte göra samma fel. ChatGPT-konvots §3 |
| Extraktion: hur många? | 2 (E1 metodväg + E2 kontrollväg) | Känd terräng (källkartan styr). Diffar de ofta → öka |
| Våg i ritningen | Inre container i skill-containern ("våg-grupp") | Kim ser redundansen visuellt; kontraktet uppdaterat: inre container ≠ skill |
| Konsensus-regel | Fakta = bekräftat av ≥2 vägar; KONFLIKT/ENSAMT → verifieringsvåg, max 2 varv | Hård styrning på beviskrav, mjuk på metod (ChatGPT-konvots nivåmodell) |
| Kvarstående diff | manual_review.md + Status PARTIAL — aldrig tyst | Kims 95/5-krav: det osäkra ska SES, inte gissas bort |
| Container-spawn | Adoptera direkt + ingen kaskad för containrar | Tog bort det inkonsekventa mellanläget (trasiga pil-ankare, P4:s "slukade nod") |
| Subgraph-medlemskap | `childOfContainerId` är enda sanningen | Position-gissning bröt round-trip (P3:s fynd — mermaid ≠ JSON) |

## 3. Nuläge MFP-pipelinen

1. **mfp-site-intelligence v2** — BYGGD (ej körd i v2-form). v1 körd mot Canon (Akamai-fynd).
2. **mfp-sortiment** — BYGGD (ej körd). Startar från official_source_map.md.
3. **mfp-spec / mfp-dashboard** — stubbar.
Dirigent: `flode`. Kör: "kör flödet mfp-site-intelligence Canon Sverige multifunktionsskrivare"
(ger ny källkarta med konsensus-spår) → "kör flödet mfp-sortiment".

## 4. Nästa steg

1. **Kim verifierar v73 på iPhone:** öppna appen (ska visa v73) — testa: lägg 3 noder
   (hamnar de fritt?), Skill-chip (wrappar mitten + "Vad heter skillen?"-dialog vid spara),
   Redigera-arket (prompt överst, svep kastar inte text).
2. **Kör Skill 1 v2 mot Canon** — validerar redundans-mönstret i verkligheten (gap-analys,
   konsensus, varv). Sedan Skill 2 → product_candidates.md.
3. **Kvarstående UX-fynd** enligt prioriteringen i UX_PERSONA_AUDIT.md:
   UX-111/112 (pan-stölden + handtag utanför skärm — kräver iPhone-verifiering),
   UX-113 (text-ledtråd för nybörjare), UX-114/115 (a11y i ark/paneler + meny-alternativ
   till gester), UX-122 (skill-kedje-mall i Mallar — litet, direkt MFP-värde).

## 5. Var allt finns
- Audit: `UX_PERSONA_AUDIT.md` (repo). Persona-rapporter + screenshots: `/tmp/ux-audit-v72/` (försvinner vid omstart).
- Skills: `~/.claude/skills/mfp-site-intelligence/` (v2), `~/.claude/skills/mfp-sortiment/` (ny).
- Ritade specs: iCloud-Mermaid: `mfp-site-intelligence.md` (v2), `mfp-site-intelligence-v1-arkiv.md`, `mfp-sortiment.md`, `mfp-pipeline.md` (uppdaterad).
- Målbilden: `~/Downloads/ChatGPT-!MERMAID BETA.md` + memory `project_mfp_pipeline` (v73-blocket).
- idb-miljön: venv OMBYGGT till Python 3.13 (`brew install python@3.13`; gamla venv:et dog när brew bytte till 3.14). Tomt a11y-träd → starta om simulatorn + companion.
