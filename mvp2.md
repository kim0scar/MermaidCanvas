# MVP-2 — Visual Mermaid Spec: översättningssäkert språk

Detta dokument är nästa byggsteg. Det baseras på Perplexity-svaret om hur MermaidCanvas ska bli **översättningssäker mot Godot och SwiftUI** — inte ett fritt ritverktyg, utan en avgränsad semantisk UI-spec.

> Kortversion: Mermaid är *semantisk* blueprint, inte pixelperfekt design. Appen ska aktivt stoppa konstruktioner som inte går att översätta stabilt vidare.

---

## Grundprincipen

Appen ska följa två lager (samma som i [METOD-VISUELL-DIALOG.md](METOD-VISUELL-DIALOG.md), men med skarpare regler):

| Lager | Vad det är | Var det bor |
|---|---|---|
| **1. Mermaid-diagram** | Struktur, relationer, grov layout (noder, edges, subgraphs, klasser, styling) | I `.md`-fil, ```mermaid```-block |
| **2. Sidecar-metadata** | Det Mermaid INTE bär stabilt: safe-area-roll, anchor, prioritet, z-ordning, target-plattform, accessibility-text | I `.md`-fil, `<!-- mermaidcanvas-state -->`-block (state-JSON) |

**Princip:** *"Lossless enough for structure, lossy by design for art direction."* — fånga hierarki, flöden, semantik och layoutrelationer exakt; försök ALDRIG vara pixelperfekt design.

---

## Visuell grammatik (strikt delmängd)

Bara följande Mermaid-konstruktioner får genereras:

| Funktion | Tillåten representation | Översätter till Godot | Översätter till SwiftUI | Regel |
|---|---|---|---|---|
| Skärmram | `subgraph Screen_Home["iPhone Screen / Home"]` | `Control`-root eller `CanvasLayer` | Root `View`/`NavigationStack` | En skärm = ett subgraph |
| Huvudzon | `rect` / `@{ shape: rect }` | `PanelContainer`, `MarginContainer`, `VBoxContainer`, `HBoxContainer` | `VStack`, `HStack`, `ZStack`, `Form`, `List` | För header, content, footer, HUD-zoner |
| Primär knapp | Rundad rektangel / `rounded` | `Button` (primary theme) | SwiftUI `Button` med primär stil | Klass `btn_primary` |
| Sekundär knapp | Rektangel / `rect` | `Button` (secondary theme) | `Button` med sekundär stil | Klass `btn_secondary` |
| Val/branch | Diamant / `decision` | `if`, routing, conditional nav | `if`, `switch`, navigation-conditional | Endast för logik, inte layout |
| Start/slut i flöde | Cirkel, stadium, dubbelcirkel | Entry/exit scene, app start, flow end | Onboarding-screen, end-screen | Bra för navigation och onboarding |
| Data/persistens | Cylinder / `database` eller `datastore` | Save state, profile, settings | UserDefaults, CoreData, AppStorage | Endast semantisk markör |
| Kommentar/not | `text`, `brace`, comment-former | Dokumentation, inte runtime-UI | Dokumentation, inte runtime-UI | Får ALDRIG tolkas som faktisk komponent |
| Ikon/bild | `icon` eller `image` shape | Referensasset, placeholder | `Image`/`SF Symbol` referens | Får inte vara enda källan till layout |

---

## Färger som semantik, inte estetik

Inga fria hex-koder överallt. Bara ett litet antal semantiska klasser via `classDef`:

| Klass | Semantisk roll | Default-färg (kan ändras i tema) |
|---|---|---|
| `surface` | Bakgrund, kort, paneler | `#F8FAFC` |
| `primary` | Huvudaction, brand | `#3B82F6` |
| `secondary` | Sekundär action | `#94A3B8` |
| `accent` | Highlight, focus | `#A78BFA` |
| `danger` | Destruktiv action, fel | `#EF4444` |
| `success` | Bekräftelse, OK | `#10B981` |
| `warning` | Varning | `#F59E0B` |
| `muted` | Inaktiv, disabled | `#CBD5E1` |

Hex-värdena bor i ett gemensamt **tema/lexikon** i Markdown (`lexicon.md`), inte per-fil.

---

## Regler — vad appen ska **stoppa**

App-validatorn ska blockera följande, eftersom de inte översätter stabilt:

1. **Fri överlappning** av former (Mermaid layout-motorerna `dagre`/`elk` placerar noder automatiskt — manuell overlap blir oförutsägbart). Overlay tillåts bara som *semantisk flagga i metadata*.
2. **Fria koordinater** i ```mermaid```-blocket (Mermaid stödjer det inte — koordinater bor i state-JSON som *hint*, inte source of truth).
3. **För många färgklasser** (max de 8 ovan; egna hex bara via tema).
4. **För långa labels** i noder (>40 tecken). Lång copy → flytta till metadata.
5. **Okända shape-symboler** eller egen påhittad syntax (validator kollar mot allowlist).
6. **Råa hex-koder utanför temat**.

---

## Text-regler

| Var | Innehåll | Max-längd |
|---|---|---|
| **Node-text** | Komponentnamn eller kort label | ≤40 tecken |
| **Edge-text** | Handling eller villkor: "tap", "success", "timeout", "auth ok" | ≤25 tecken |
| **Subgraph-text** | Skärmnamn | ≤30 tecken |
| **Längre copy, a11y-text, states, platform-notes** | Flyttas till metadata under diagrammet | obegränsat |

---

## Pilar — fasta betydelser

| Pil | Betydelse | Exempel |
|---|---|---|
| `-->` | Användarflöde / navigation | "tap Start → Home" |
| `-.->` | Sekundärt beroende / async / hjälpflöde | "logger → analytics" |
| `==>` | Blockerande beroende / kritisk väg | "auth → home (kräver token)" |
| `pil med label` | Trigger | `A -->|"tap"| B` eller `A -->|"timeout"| C` |

**Varning om subgraphs:** Om noder inne i ett subgraph länkas utåt kan dess interna `direction` ignoreras och ärva förälderns. **Regel:** yttre flöden kopplas till en *skärmnod* eller *entry/exit-nod*, inte direkt till alla UI-element inuti.

---

## Appfunktioner som krävs

Appen ska inte bara vara en editor — den ska vara en **översättningssäker** editor som aktivt stoppar sådant som inte blir stabilt:

| Funktion | Varför den behövs | Status i v20 |
|---|---|---|
| iPhone-canvas med fördefinierade skärmramar | Skissa "på skärm", relatera till edges, safe areas, HUD-zoner | ✅ delvis (iPhone-overlay finns) |
| Mermaid-export med strikt delmängd | För stor frihet → skör översättning | ⚠️ delvis (alla shape-typer exporteras, ingen allowlist än) |
| **Validerare för otillåtna konstruktioner** | Stoppar fri overlap, fria koordinater, för många färger, för långa labels | ❌ saknas |
| **Sidecar-metadata per nod** | Anchor, safe-area-roll, overlay-flag, storleksklass, prioritet, state, target hints | ✅ finns (state-JSON), behöver utvidgas |
| **Två lägen: Screen Layout och Flow** | UI-hierarki och "trycker här → kommer hit" | ✅ finns (UI/Flow specType) |
| **Exportprofiler: Godot och SwiftUI** | Godot → Control + containers + theme; SwiftUI → navigation + view-hierarki | ❌ saknas — kritisk |
| **Claude-kontrakt i Markdown** | iCloud/Markdown-arbetsmodell där Claude läser samma filer | ✅ finns |

---

## Två filer som behöver skapas

### 1. `visual-language-spec.md`
Beskriver hela standardspråket — vilka former, klasser, pilar, regler som finns. **Den autoritativa referensen.**

### 2. `lexicon.md`
Beskriver:
1. Tillåtna former och deras betydelse
2. Tillåtna klasser/färgroller
3. Tillåtna pilar och vad de betyder
4. Hur en **screen**, **panel**, **button group**, **HUD**, **modal**, **sheet**, **toast**, **tab bar**, **overlay** uttrycks
5. Hur detta översätts till Godot resp. SwiftUI
6. Vad som uttryckligen **INTE** är tillåtet

**Minimikontrakt:**
> Inga fria overlays, inga absoluta koordinater, inga okända former, inga råa hex-koder utanför temat, ingen lång brödtext i noder, och all avancerad semantik måste definieras i `lexicon.md`.

---

## Byggsteg för MVP-2

| Steg | Vad | Filer |
|---|---|---|
| **1** | Skriv `visual-language-spec.md` (standardspråket) | NY: `visual-language-spec.md` |
| **2** | Skriv `lexicon.md` (egna symboler + översättningsregler) | NY: `lexicon.md` |
| **3** | Validator i appen som blockerar otillåtna konstruktioner | NY: `app/.../Mermaid/MermaidValidator.swift` |
| **4** | Allowlist av shape-typer per spec_type | UTÖKA: `ShapeCategory.swift`, `SpecType.swift` |
| **5** | Sidecar-metadata utvidgning: `anchor`, `safe_area_role`, `overlay_flag`, `size_class`, `priority`, `state`, `target_hint` | UTÖKA: `ShapeNode.swift`, `MermaidGenerator.swift`, `MermaidParser.swift` |
| **6** | Exportprofil Godot: `MermaidCanvas.md` → `*.gd` / `*.tres` | NY: `app/.../Export/GodotExporter.swift` |
| **7** | Exportprofil SwiftUI: `MermaidCanvas.md` → `*.swift` View-struct | NY: `app/.../Export/SwiftUIExporter.swift` |
| **8** | Två-läges-toggle i appen: **Screen Layout** vs **Flow** (skiljt från specType) | UTÖKA: ContentView, ToolbarView |
| **9** | Allowlist-validering vid save: appen vägrar spara om diagram bryter regler | UTÖKA: `CanvasFileManager.swift` |
| **10** | Exempel-canvas: Home screen, HUD, navigationsflöde — som referens i appen | NY: `arkiv/example-home.md`, `arkiv/example-hud.md`, `arkiv/example-nav.md` |

---

## Verifierings-test för MVP-2 (KRITISK GRIND)

1. Kim ritar en **Home Screen** i UI-läge med:
   - 1 skärmram (`Screen_Home`)
   - 3 zoner (header, content, footer)
   - 2 primary buttons + 1 secondary
   - 1 navigationspil
2. Claude läser filen (utan kontext) och genererar:
   - SwiftUI-vy som matchar layouten
   - Godot-scen (`.tscn`-fragment) som matchar layouten
3. Kim kompilerar och kör båda. Stämmer det med vad han ritade? → MVP-2 godkänd.

---

## Vad MVP-2 INTE innehåller

- Pixelperfekt design (det är inte Mermaid:s syfte)
- Animationer (kommer senare som metadata-fält)
- Bilder/assets (referenser bara, ingen embedding)
- Dynamisk data (state-machines kommer i MVP-7 flow-läge)

---

## Risker

| Risk | Mitigering |
|---|---|
| Allowlist gör appen för restriktiv | Lägg "varna men tillåt"-läge vid första misstag, blockera vid spara |
| Godot/SwiftUI-exportörer divergerar i tolkning | Skriv `lexicon.md` FÖRST. Båda exportörer läser samma kontrakt. |
| Kim vill rita något som inte är översättningsbart | Visa förklarande felmeddelande: "Den här konstruktionen kan inte översättas. Gör det här istället: ___" |
| Validator blir för komplex | Bygg den i 3 nivåer: form-check, semantik-check, target-check. Bara form-check är blockerande. |

---

## Beslutspunkt innan bygget startar

Kim avgör:
1. **Vilket exportmål ska byggas först — Godot eller SwiftUI?** → **GODOT FÖRST** (Kim 2026-05-15). Varje exportmål blir egen del i appen (eget spec_type-läge) med egna regler.
2. **Ska validatorn blockera eller varna?** (rekommendation: varna i UI, blockera vid spara)
3. **Ska `lexicon.md` skrivas av Claude som första steg, eller bestäms innehållet av Kim?** → Claude skrev utkast: [godot-lexicon.md](godot-lexicon.md).

---

## Etapp Godot — vad som är klart (v21)

✅ `SpecType.godot` finns som eget läge i toppen
✅ 8 godot-kategorier: `godot_scene`, `godot_control`, `godot_container`, `godot_panel`, `godot_button`, `godot_label`, `godot_signal`, `godot_script`
✅ Egen färgpalett per Godot-nodtyp (matchar Godot brand-blå för scene)
✅ Preview-fliken visar scene-träd istället för iPhone-frame när läge = Godot
✅ `godot-lexicon.md` — kontraktet för Godot-läget (regler, mermaid-mapping, .tscn/.gd-export)

## Etapp Godot — vad som återstår

⬜ Validator: blockera otillåtna konstruktioner per `godot-lexicon.md`
⬜ Exportör: .tscn-fil-generering från scene-trädet
⬜ Exportör: .gd-fil-stub-generering för varje godot_script-nod
⬜ Spara-flöde: spara .md + .tscn + .gd parallellt
⬜ Test-canvas i appen: rita main menu, exportera, importera i Godot 4.3

## Etapp SwiftUI (efter Godot)

Samma mönster: `SpecType.swiftui` + `swiftui-lexicon.md` + exportör. Skiljs helt från Godot — varje exportmål har egna regler.
