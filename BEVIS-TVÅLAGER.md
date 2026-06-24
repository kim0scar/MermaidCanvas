# BEVIS — appens två-lager-fundament (hur det är tekniskt löst)

*Skapad 1.0 (2026-06-23). Svarar på Kims fråga: "bevisa tekniskt hur export/import alltid bär med sig vad som är mermaid och vad som är app-lagret — så en vän får upp samma bild OCH en AI förstår allt och kan bygga vidare."*

---

## Kort (det du vill veta)

✅ **En vän** får upp exakt samma bild (öppnar `.md` i mermaid.live).
✅ **Du** kan rita → kopiera → radera → klistra → få *exakt* samma (noll avvikelse).
✅ **En främmande AI** som tar emot filen förstår vad som är mermaid och vad som är ditt app-lager — och kan bygga vidare **utan att förstöra dina funktioner**.

Det sista var ett **gap** före 1.0: förklaringen (AI-ramverket) låg bara bakom en knapp i appen — den följde inte med i filen. **1.0 stänger gapet**: ramverket bäddas in i *varje* exportfil, och ett test tvingar att det aldrig tyst faller bort igen.

---

## Så ser en exporterad fil ut (fyra lager i EN fil)

```markdown
---
title: Min ritning            ← (1) frontmatter: titel/typ/plattform
spec_type: flow
platform: blank
shape_packs: basic
last_updated: 2026-06-23
---

# Min ritning

Genererad 2026-06-23T10:00:00Z.

```mermaid                     ← (2) REN MERMAID — det vännen ser i mermaid.live
%%{init: {"flowchart":{"curve":"basis"}}}%%
flowchart TD
    %% canvas-size: 1200,900   ← (3) %%-rader: app-lagret, osynligt i mermaid.live
    n1(("Start")):::flow
    %% n1 pos: 300,300
    n2{"OK?"}:::flow
    %% n2 pos: 500,420
    n3(["Klar"]):::flow
    %% n3 pos: 700,540
    %% n3 shape-type: pill      ← egen form: identitet bevaras även i ren mermaid
    n1 --> n2
    n2 -->|"ja"| n3
    classDef flow fill:#deedfd,stroke:#74b0e6
```

<!-- mermaidcanvas-state        ← (4a) STATE-JSON: hela modellen, BOKSTAVLIGT noll avvikelse
{
  "canvas": { "width": 1200, "height": 900 },
  "nodes": [ { "label": "Start", "type": "circle", "x": 300, "y": 300, ... }, ... ],
  "edges": [ ... ]
}
-->

---

> 🤖 **Till en AI som tar emot denna fil:** sektionen nedan beskriver appens två lager …

# MermaidCanvas — vad du får använda i mermaid (genererat 1.0)   ← (4b) INBÄDDAT AI-RAMVERK (1.0)
Appen är ett TVÅ-LAGER-system: mermaid är transporten, appen lägger till ett eget lager …
## NATIVE mermaid-former …
## EGNA former (ritas som närmaste native; identitet via %% shape-type) …
## Kanter …
## APP-EGNA funktioner (bärs i mermaid utan skada) …
```

*(Exakta id:n och färg-hex genereras av appen; strukturen ovan är formatet koden producerar — verifierat av testerna nedan.)*

---

## Vad de fyra lagren gör

| # | Lager | Vem läser | Garanti |
|---|---|---|---|
| 1 | **Frontmatter** (`---`) | appen | titel/typ/plattform exakt |
| 2 | **Ren mermaid** (```mermaid-block) | **vännen** i mermaid.live + appen | diagrammet renderar identiskt |
| 3 | **`%%`-rader** | appens fallback-parser + människa/AI | app-fält överlever även REN mermaid |
| 4a | **`<!-- mermaidcanvas-state -->`** | appens state-parser | **byte-exakt** round-trip |
| 4b | **Inbäddat AI-ramverk (1.0)** | **främmande AI** | filen är själv-förklarande |

**Två lager, sagt rakt ut:** mermaid är *transporten* (portabel kropp). Appen är *renderaren* med ett eget tilläggslager (`%%` + state-JSON) = "MermaidCanvas Extended". Egna former (iPhone-ram, tabell, oktagon …) ritas i ren mermaid som närmaste native-form; identiteten bärs av `%% shape-type`. Det är mermaids gräns — inte en bugg.

---

## Hur import fungerar (varför inget tappas)

`MermaidParser.parse()` (`Sources/Mermaid/MermaidParser.swift`):

1. **Finns state-blocket?** → bygg modellen ur det. **Byte-exakt** (full precision, sorterade nycklar). Det inbäddade AI-ramverket och allt annat ignoreras — bara `<!-- mermaidcanvas-state -->` läses. Detta är din "rita→kopiera→radera→klistra".
2. **Saknas det?** (en vän strippade det, eller en AI ritade för hand i ren mermaid) → fall tillbaka på mermaid-strukturen + `%%`-raderna. `%% shape-type` vinner över den ritade kroppen, så egna former återskapas rätt.

Det inbäddade ramverket ligger **efter** state-blocket med avsikt: parsern hittar alltid det riktiga state-blocket först, så ramverket (som *nämner* strängen `<!-- mermaidcanvas-state -->` i sin text) kan aldrig förvirra inläsningen.

---

## BEVISET — testerna som maskinellt tvingar allt detta

Detta är inte en åsikt. Varje garanti har ett test som blir RÖTT om den bryts (körs i pre-commit + vid deploy):

| Garanti | Test | Vad det bevisar |
|---|---|---|
| **Byte-exakt round-trip** | `RoundTripFidelityTests` | Varje formtyp + varje fält överlever generera→parsa, fält-för-fält. `test_idempotent`: generera→parsa→generera = **byte-identiskt**. `test_nonIntegerPosition_exactRoundTrip`: 321.7 överlever exakt (ingen kapning). |
| **Inget fält glider** | `StateJSONSymmetryTests` | Ett fält i taget sätts till icke-default och måste överleva — fångar om någon lägger till på skriv-sidan men glömmer läs-sidan. |
| **Facit ↔ generator i synk** | `AppCapabilitiesCoverageTests` | BIJEKTION: ingen `%%`-nyckel generatorn skriver saknas i facit, och ingen facit-nyckel saknas i output. Menyn + ramverket täcker varje form. |
| **Spec:en följer ALLTID med (1.0)** | `AppCapabilitiesCoverageTests.test_exportEmbedsFrameworkAndStillRoundTrips` | (a) varje exportfil + skill-fil **innehåller** AI-ramverket; (b) inbäddningen bryter **inte** state-round-trippen (formen läses tillbaka exakt). |
| **Ren mermaid renderar** | `scripts/mermaid-conformance.mjs` (mermaid.parse) + `scripts/mermaid-render-check.mjs` (headless Chrome) | Det vännen ser i mermaid.live parsar OCH renderar på riktigt. |

**Single source of truth:** allt (menyn "Mermaid vs app", AI-ramverket, embed-blocket) genereras ur `AppCapabilities.swift`. Lägger någon till en form/funktion utan att uppdatera facit → bijektions-testet blir rött (CLAUDE.md regel 15). Därför kan ramverket **aldrig bli inaktuellt** — det Kim ser, det vännen ser, och det AI:n läser är samma sanning.

---

## Vad 1.0 ändrade (gapet som stängdes)

- **Före:** `frameworkText()` (förklaringen) fanns bara bakom in-app-knappar ("Kopiera AI-ramverk" / import-mallen). En vän som fick en sparad `.md` fick datat (`%%` + state-JSON) men **inte** spec:en som förklarar vad nycklarna betyder.
- **Efter (1.0):** `AppCapabilities.embeddedFrameworkBlock()` läggs in sist i `CanvasDocument` (normal spara) + `SkillFileComposer` (skill-export). Nu är **varje** fil själv-förklarande. Nytt test tvingar att det följer med.

Filer: `Sources/App/Models/AppCapabilities.swift` · `Sources/App/Persistence/CanvasDocument.swift` · `Sources/App/Persistence/SkillFileComposer.swift` · `Sources/Mermaid/MermaidParser.swift` · `UnitTests/{RoundTripFidelity,StateJSONSymmetry,AppCapabilitiesCoverage}Tests.swift`. Full fält-spec: `EXTENDED-FORMAT.md`.
