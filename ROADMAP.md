# MermaidCanvas — Roadmap

Versioner och vad de innehåller. Senaste först.

## Aktuell version: v1.1 (build v90) — "Visio hoppa-in (underflöden)"

*Tema:* Facit-täckningsgrind (bijektion generator↔facit) + ärlig regel 15. Facit-menyn
redesignad (färg=överlevnad, riktiga glyfer, sök, sticky copy). JPG-export. Import-mallen
fixad (lärde ut den kraschande `<--`). Snabb-mallar (AI-Skill/UI/Arkitektur). Snabb-navknapp.
KVAR: Fas 2 export-legend (gated) + mega-projekt (OSX/Visio-drill/multi-fil). 197 tester.

## v0.9 (build v85) — "AI-ramverk + Mermaid-vs-app-vy"

*Tema:* Milstolpe **v0.9**. `AppCapabilities.swift` = single source of truth för "vad appen kan
visa → vad en AI får använda i mermaid". Driver in-app-vyn "Mermaid vs app-funktioner" (Kim ser
native vs app-egna + bärare) + copy-paste-bar AI-ramvers-text (alltid genererad ur kod → aldrig
stale). CLAUDE.md regel 15: varje ändring håller export↔import + AppCapabilities aktuell (tvingat
av uttömmande switch + test). 193 tester, render-grind 3/3.

## v84 — "V79-feedback-svep (7 features)"

*Tema:* På Kims /goal — 3 scoping-agenter + 7 byggda features ur V79-feedbacken: 🔒 lås form
(hänglås), 3 lager (underst/mellan/överst, round-trippar i mermaid), ↪️ redo (ångra båda håll),
"Spara Mermaid inom container", beroendepil-meny i kategorier, container fri-resize nere höger,
markera-flera ut ur huvudmenyn. Lås+lager round-trippar även på container. Resten av listan =
idébank 💡#9–11 (OSX-app, Visio-drill, edge-routing m.m.). 191 tester, render-grind 3/3.

## v83 — "Pill-fix + fundament-verifiering"

*Tema:* Pill-formen rättad (138×74 — var för platt). **Fundamentet bevisat:** alla basformer
ritade med text + kategori-färger, exakt mermaid dumpad + renderad i RIKTIG mermaid (headless
Chrome) + jämförd mot app → native-former identiska, egna former visas som närmaste native men
text+färg+identitet matchar (re-import exakt). Roten städad. 188 tester, render-grind 3/3.

## v82 — "Fil-glyfer + UI-mall (steg 8 del 2 + steg 9)"

*Tema:* Fil-former (MD/Excel) får igenkännings-glyf på canvasen. **UI-mall:** Mallar-menyn
borta → iPhone 15/16 Pro som chips under UI; modellnamnet UTANPÅ ramen (skärmytan fri);
phoneFrame bara proportionell resize. **phoneFrame-som-container** (`actsAsContainer`):
former på skärmen blir barn, följer med vid flytt, round-trippar via state-JSON. State-JSON
nu byte-stabil (`.sortedKeys`). 188 tester, render-grind 3/3, round-trip 3/3 stabil.

## v81 — "Exportera som bild + render-trogen grind (steg G+H)"

*Tema:* Ny funktion **"Exportera som bild"** — PNG av enbart den ritade ytan via samma vyer
som canvasen (kan aldrig avvika). Export+render-jämförelsen avslöjade + tätade en noll-
avvikelse-bugg: bakåtpil `<--` kraschade RIKTIG mermaid (mermaid.live) fast `mermaid.parse`
släppte igenom → skrivs nu som omvänd framåtpil. Grinden blev **render-trogen**
(`mermaid-render-check.mjs`, headless Chrome, vid deploy). G2: basfigur-polish + look-alikes.
G1: `EXTENDED-FORMAT.md` (app-only-spec) + `%% canvas-size` round-trippar i ren mermaid.
187 unit-tester gröna, render-grind 3/3.

## v80 — "noll-avvikelse-garantin (STEG F)"

*Tema:* Round-trip bevisat förlustfritt + maskinellt tvingat (pre-commit + deploy). Extended-
lagret (`%%` + state-JSON) bär ALLT mermaid saknar. Clamp borttaget ("filen är sanningen").
Facit chmod 444. 186 tester, 3/3 fixtures, två agent-par bekräftade noll avvikelse.

## v79 — "arkitektur-ombyggnad KLAR (milstolpe MA)"

*Tema:* MA slutförd. Funktionellt identisk med v77/v78, men ALLA fyra monoliter är nu
nedbrutna under 300 rader via extension-uppdelning (stored/@Published-fasaden kvar i
original-typen → rerender oförändrad): CanvasView 1781→297, ToolbarView 1069→237,
ContentView 691→225, CanvasModel 857→56. 171 unit-tester gröna + arch-check grön efter
varje steg; verifierat i sim (pil-rendering, toolbar-rader, sheets, lägg-form + ångra).
Lagerindelning + maskinell grind + 36 skyddstester + `se-appen`-loopen kvar från v78.
Versionen härleds från AppVersion (v79 → 1.79.0 / 79).

## v78 — "arkitektur-ombyggnad, checkpoint 1"

*Tema:* milstolpe MA. Funktionellt identisk med v77, men stor strukturell omgång:
lagerindelning + maskinell arch-grind (`scripts/arch-check.py`) + 36 nya skyddstester
(djup round-trip) + `se-appen`-loopen (Claude ser/styr appen i sim själv). CanvasView
bröts 1781 → 1070 rader i små verifierade steg. Återstående ombyggnad: se
`ARKITEKTUR-OMBYGGNAD.md`. Versionen härleds nu från AppVersion (v78 → 1.78.0 / 78).

## v77 — "krocksäkert exportnamn + stabil Spara-dialog"

*Tema:* exporttestet (Claude körde hela Kims export-väg i appen) avslöjade att
exportens default-namn var samma som ritningsfilen — risk att skriva över ritningen
tyst. Nu heter exporten alltid `skill-<nr>-<namn>.md`. Spara-dialogen fick också
0,9 s presentation-marginal (uteblev ibland tyst på iOS 26).

## v76 — "cylinderfix + centrerad container-titel"

*Tema:* UI-granskning där Claude körde appen själv (iphone-takeover-metoden).
CylinderShape fick ellips-botten (cirkelbågen fick breda cylindrar att se ut som
koppar utanför ramen), container-titeln centrerades så den syns mitt i breda
skill-containrar, och demo-skill-3-ritningen fick riktig containerstorlek +
nodbredder. Nytt manuellt test TakeoverUIGranskning (öppnar fil via Filer-väljaren,
fotograferar i tre zoomlägen).

## v75 — "Spara som-dialog för skill-export + demo-skill-2"

*Tema:* Kims test visade att exporten hamnade osynligt i appens egen mapp (sandlådan
nekar skrivning bredvid filer öppnade via Filer). Nu öppnar "Spara skill som fil" en
riktig **Spara som-dialog** — Kim väljer mappen, alerten säger filnamnet, inget göms.
Ny ritning **demo-skill-2.md**: hela skillen i EN box, vänster→höger som n8n
(input → script → WebSearch-verktyg → agent → grind → pass/fail → output), körd
framgångsrikt av främmande agent med riktig webbsökning. UI-testet kör hela kedjan
inklusive Files-dialogen. 23 unit-testsviter gröna.

## v74 — "portabel skill-export + skill-nummer"

*Tema:* M2 i PROJEKTPLAN.md — exporten ska fungera på VILKEN Claude Code som helst,
på någon annans dator, utan skills och utan projekt. Kim ritar → exporterar → ger bort filen.

1. **Portabel export:** "Spara skill som fil" bäddar nu in det frysta exekverings-kontraktet
   (`EXPORT-KONTRAKT.md` v1 → `SkillExportContract.swift`) + legend + skill-frontmatter
   (skill_name/skill_nr/contract_version) via nya `SkillFileComposer.swift`.
2. **Skill-nummer (ordning i kedjan):** skill-containrar kan få nummer — headern visar
   "Skill 1 · mfp-site-intelligence". Round-trippar via state-JSON och `%% skill-nr`.
3. **Parserfix:** skill-kategorin överlever nu ren-mermaid-round-trip (id-prefix, var hårdkodad .ui).
4. **Container-städning:** tydligare skill-ram, lång rubriktext krymper/trunkeras.
5. **Bevisen:** främmande agenter (utan skills/projekt) körde portabla filer: pass → resultat.md,
   fail-injektion → manual_review.md (grinden fångade), tom nod → ärligt stopp med exakt
   saknas-lista. UI-testet `V74SkillExportUITest` körde APPEN själv: skapade skill-container,
   satte Skill 1, exporterade — filen verifierad. 23 unit-testsviter gröna.

## v73 — "audit-fixar + redundans-pipeline"

*Tema:* Kim bad Claude testa appen som användare och bygga målbilden från ChatGPT-konvot
"!MERMAID BETA" (determinism genom process: subagent-par, gap-analys, konsensus). Full
UX-audit kördes (Claude själv + alla 6 personas via idb, två simulatorer parallellt) →
`UX_PERSONA_AUDIT.md` (22 unika fynd, 9 fixade direkt). Jämfört med v50.6-auditen är
8 av 14 gamla fynd nu åtgärdade och bekräftade.

**App-fixar (alla verifierade i sim):**
1. **UX-110 (HÖG, round-trip):** subgraph-medlemskap genereras nu från `childOfContainerId`
   (= state-JSON:s sanning), inte positions-gissning. Container adopterar barn direkt vid
   spawn och kaskadas inte själv. Mermaid och JSON kan inte längre säga olika saker.
2. **UX-101:** kaskad-steg 96pt — nya noder hamnar fritt i stället för i en hög (v50.6-arvet).
3. **UX-102:** "Spara skill som fil" frågar efter namn (döper även containern) — slut på "skill.md"/"Grupp".
4. **UX-103/104:** prompt-fältet överst i Redigera-arket med ärlig rubrik; svep kan inte
   längre kasta osparade ändringar.
5. **UX-105 (HÖG, a11y):** canvas-former finns nu i a11y-trädet med svensk label — VoiceOver
   OCH AI-agenter ser canvasen. Pilhandtaget heter "Skapa pil".
6. **UX-106:** tomma noder visar typ-platshållare ("Script", "Bevis"...) tills Kim döper dem.
7. **UX-107/108:** UI- och Prompt-Process-paketen fick chips (var döda segment); ingen radbrytning.

**Skill-lagret (utanför app-koden):**
- **mfp-site-intelligence v2:** discovery görs av 4 oberoende subagent-vägar
  (meny/sök/sitemap/API) → gap-analys → konsensus-grind → verifieringsvåg (loop max 2 varv)
  → manual_review för det obevisade. Ritad spec + SKILL.md synkade; v1 arkiverad.
- **mfp-sortiment (Skill 2) byggd:** E1 (routerns metod) + E2 (oberoende kontrollväg) per
  sortimentsida, samma gap/konsensus-mönster. Output: product_candidates.md.
- **SKILL-KEDJA-KONTRAKT.md:** redundans-mönstret låst (våg-grupp = inre container ≠ skill,
  gap-analys, konsensus-grind, verifieringsloop, redundanspolicy 4→2 vägar).

Kvarstående fynd (UX-111–122) prioriterade i `UX_PERSONA_AUDIT.md`. Tester: unit-sviten grön.

## v72 — "save/handover (dokumentations-milstolpe)"

*Tema:* Trygg savepoint inför `/clear`. Ingen feature-/logik-ändring — bara AppVersion-bump +
fullständig dokumentation. Ny **`arkiv/HANDOVER-v72.md`** (beslutslogg: vägval + varför för
v69→v72, MFP-pipelinens nuläge, nästa steg). Plan-filen (`vi-ska-bygga-en-magical-knuth.md`)
uppdaterad från v61.2 → v72. CLAUDE.md:s spar-tabell pekar nu på MFP-skill + iCloud-canvas-filer
+ handover. ARKITEKTUR v71 arkiverad. Läs HANDOVER-v72 för helheten.

## v71 — "legend som alltid-närvarande översättare"

*Tema:* Kim ville att varje skill-flödes mermaid ALLTID bär en legend som översätter varje
formtyp (kategori) → betydelse, så Claude läser koden självförklarande. Förut: legenden var
manuell och oftast tom = ingen översättare.

**v71:**
1. **Auto-legend:** `MermaidGenerator.generate()` skriver nu en `%% legend <kategori>: <text>`
   per ANVÄND formtyp, alltid. Manuellt ifylld rad (LegendPanel) vinner, annars kategorins
   `pickerHint` som standard. Legenden översätter kategorin (en rad per typ), inte varje ruta.
2. **MermaidCodeSheet** skickar nu `model.legend` (saknades → kod-vyn tappade Kims override).
3. **State-JSON** lagrar fortsatt bara Kims MANUELLA legend-poster (defaults pollar inte staten).
4. **Note vs prompt (bekräftat, ingen kodändring):** `prompt` = skill-instruktionen; `note` =
   Kims privata kommentar som round-trippar i filen men ALDRIG blir del av skillen (kontraktet).
- Nya tester: V71Tests (3). Unit-sviten grön.

## v70 — "skill-containrar: spara en container som egen skill-fil"

*Tema:* Kim utredde arkitekturen för hur ritade flöden blir skills + navigering helhet↔skill.
Research (Claude Code-dokumentationen) + kodkartläggning → Kims egen idé valdes: **en
pipeline-fil = helheten, varje skill = en container, varje container ejectbar.** Det matchar
SKILL-KEDJA-KONTRAKTet och var redan ~80 % byggt (`generateForContainer` + "Kopiera som skill").

**v70:**
1. **"Spara skill som fil":** tryck-håll en container → spara just den containern (+ barn +
   kant-memory) som EGEN `.md` i iCloud bredvid pipeline-filen — utan att byta aktuell fil.
   Förenar en-fil och flera-filer: en pipeline-fil knoppar av fristående skill-filer på begäran.
2. **`containerSubset()`** bröts ut ur `generateForContainer` (återanvänds av både urklipp
   och fil-export). `CanvasFileManager.saveSkillFile` + namn-sanering.
3. **Tydlig skill-container:** hexagon-markör i container-headern när `category == .skill`.
4. **Fakta-utredning (i svar + memory):** mermaid → skill ska **konverteras till prosa-steg**
   i SKILL.md (pålitligt); mermaid kvar som referens — `flode` gör redan detta. Skill-kedjor
   orkestreras av en **dirigent** (`flode`), skill anropar inte skill direkt.
5. **`mfp-pipeline.md`** (iCloud): hela MFP-flödet i EN fil, 4 skill-containrar + handoff-filer.
- Nya tester: V70Tests (3). Unit-sviten grön.

## v69 — "process-kontroll: grind, bevis, manual + första MFP-kedjan"

*Tema:* Efter rådgivning (två AI-källor) om MFP-skrap-produkten. Dom: börja med
"hitta rätt officiell källa" (site-intelligence), inte "skrapa sida"; gå djupt på EN
kedja. Mycket fanns redan (container=skill, memory=fil, %% prompt, "Kopiera som skill").
Det som SAKNADES — och nu byggts — är process-kontroll-vokabulär för pålitliga kedjor.
Medvetet bortvalt: tung Nod-inspektör/9-fälts-formulär (skadar Kims visuella flöde).

**v69:**
1. **Grind** (`ShapeCategory.gate`, romb, rosa) — måste-passera-kontroll, semantiskt skild
   från Router (som bara väljer väg). Rådgivarens huvudpoäng.
2. **Bevis** (`ShapeCategory.evidence` + ny `ShapeType.cylinder`/`CylinderShape`) — sparade
   belägg. Cylindern är NATIVE mermaid `[(...)]` → round-trippar UTAN `%% shape-type`.
3. **Manual** (`ShapeCategory.manual`, åttahörning, röd) — mänsklig koll krävs, stoppa
   automatiken hellre än att gissa.
4. **Script** (`ShapeCategory.script`, rektangel, cyan) — deterministisk kod, ingen LLM-gissning.
5. **n8n-paletten utökad till 13 chips i 3 rader** — aktörer / kontroll (Router·Grind·Manual·Script)
   / data (MD-fil·Bevis·Prompt·Output).
6. **Första riktiga MFP-kedjan** ritad: `mfp-site-intelligence.md` (canvas-fil i iCloud) +
   skill `~/.claude/skills/mfp-site-intelligence/SKILL.md`. Validerad genom att köras mot
   Canon Sverige → `official_source_map.md`. Ersätter grova `mfp-inventory-source-pack`.
- Nya tester: V69Tests (6) + V35 utökad med cylinder. Unit-sviten grön.

## v68 — "former klara + komplett n8n"

*Tema:* Kims 6 fynd efter v67. Tre subagenter kartlade koden; två vägval valda av Kim
(bara iPhone 16 Pro nu; komplett n8n-palett). Sim-verifierat.

**v68:**
1. **Trekant:** ny liksidig `TriangleShape` bland grundformerna (de är nu kompletta).
   Round-trip som octagon/phoneFrame: rektangel-kropp i mermaid + `%% shape-type: triangle`
   + state-JSON. Mermaid blir ALLTID giltig (det var Kims krav — gamla trekanten kraschade den).
2. **+10% på canvas:** `ShapeGeometry.canvasScaleBoost = 1.10` i `width/height(for:)` (efter
   lineEnd-returen). Lättare att greppa/ändra storlek. Toolbar-chips opåverkade.
3. **Etiketter under Rad B-chipsen:** Container, Tabell, Länk, Linje, Notis får liten
   8.5pt-etikett (samma som flödes-chipsen) — tydligare vad varje ikon är.
4. **Inramad tabell-ikon:** egenritad `TableGlyph` (ram + 3×3-rutnät) ersätter SF-symbolen
   som inte såg ut som en tabell.
5. **iPhone-ram → "Mallar"-meny:** flyttad från Former-raden till en Mallar-knapp (iPhone-ikon)
   i paket-raden. Bara iPhone 16 Pro nu (förberedd för fler). Mått 180×391 = 0.460 (exakt
   16 Pro). Modellnamnet visas som diskret caption på ramen, skärmytan fri för UI-bygge.
6. **Komplett n8n-palett:** 9 chips i 2 rader — Input · Skill (container=skill-gränsen) ·
   Subagent · Agent · Verktyg / Router · MD-fil (memory, tydligare namn) · Prompt · Output.
   Hela skill-kedjan kan nu ritas (per SKILL-KEDJA-KONTRAKT + N8N-FLODE-KONTRAKT).
- Nya tester: V68Tests (7) + V35 utökad med trekant. Unit-sviten: **117/117 gröna.**

## v67 — "lugnare canvas"

*Tema:* Kims 6 fynd efter v66-test på iPhone. Tre krävde vägval (kollaps, 3D, paket-
omfång) — Kim valde. Sim-verifierat: n8n-paket, iPhone-ram (centrerad).

**v67:**
1. **n8n-PAKET:** flödesnoderna (Input/Agent/Verktyg/Router/Memory/Output) flyttade
   från Former-raden till ett eget "n8n"-paket (`ShapePack.n8n`). Paket-raden visar
   de 6 flödes-chipsen när paketet är aktivt. Färg per kategori behålls.
2. **Läs-LAPPAR på canvasen:** `NoteCardsLayer` ritas nu i CANVAS-space (inuti
   `CanvasView`-ZStacken) → lappen panorerar och zoomar med tavlan och försvinner ur
   vy när Kim panorerar bort, i stället för att sitta fast på skärmen och täcka saker.
3. **Kollaps-minus:** sitter vid pilens utgångspunkt på källnodens KANT (inte mitt på
   pilen) och syns bara när noden är markerad. Per-gren-kollaps behålls. Pilen är ren
   i normalläge. (`minusBadgePosition` utgår från `anchors.start`.)
4. **Mitten-fix:** nya former byggs i mitten. Rotorsak: `visibleCenterInCanvas` föll
   till (0,0) när `globalFrame` ännu var `.zero` (precis efter fil-öppning) → former
   landade i övre vänstra hörnet. Guarden faller nu tillbaka till canvas-mitten.
5. **iPhone 16 Pro-ram:** ny `ShapeType.phoneFrame` (bezel + skärm + dynamic island)
   bland basformerna, för att bygga UI ovanpå. Round-trip via state-JSON +
   `%% shape-type`-kommentar (självbärande mermaid). `PhoneFrameShape`/`PhoneFrameBackground`.
6. **3D-print:** medvetet skjutet till senare version (Kims val). Plan: 3D-paket
   (kub/cylinder/klot/kon), mått i prompt/anteckning, Claude Code → OpenSCAD → STL.
- Nya tester: V67Tests (5: mitten-fix, phoneFrame round-trip ×2, n8n-paket).
  V35-validering utökad med phoneFrame. Unit-sviten: **110/110 gröna.**

## v66 — "n8n-redo"

*Tema:* Kims 6 fynd (rotorsaks-analyserade av 3 par subagenter + ifrågasättare) +
egen UI/UX-svep. Sju faser, alla sim-bevisade.

**v66:**
1. **Rund båge (EdgeMath):** EN delad bezier-funktion (drawEdge + edgeAnchors, var
   duplicerad). Vinkelmedveten tension + vinkelrät sväng — fromSide-pil som pekar
   bort från målet blir rund båge (var 180°-knyck). Regressionslås: vanliga/diagonala
   pilar EXAKT oförändrade. 32 parametriska testfall.
2. **Lager-fix:** papper -3, grid -2, CONTAINER -1, pilar 0, noder 1, handtag 3 —
   containern äter inte längre pilar/etiketter. Container: BARA fri resize.
   Badges under container-headern (namnet syns).
3. **Läs-LAPPAR:** NoteCardsLayer ersätter sheet — flera lappar samtidigt på
   canvasen, skärm-space (läsbar text oavsett zoom), fält "Prompt (blir skill)" +
   "Anteckning (bara för dig)", kryss + penna.
4. **Strecket:** LineEndpointHandle drar lineEnd direkt (längd + vinkel);
   bbox följer lineEnd; migrering av gamla multiplier-linjer.
5. **Toolbar:** Rad A = 7 rena former; container → Rad B; tabell-ikon square.grid.3x3;
   rotera-offset 48→20; pil-handtag GRÖNT (arrow.up.right). NY FLÖDES-PALETT:
   Input/Agent/Verktyg/Router/Memory/Output — rätt form+kategori+färg i ett tryck.
6. **Legend + skill-export:** legend round-trippar (state-JSON + %% legend-rader)
   med redigerbar panel (Lägen → Legend). Tryck-håll container → "Kopiera som skill"
   (generateForContainer: barn via childOfContainerId + memory-noder i kanten).
   SKILL-KEDJA-KONTRAKT: prompt-vs-note, inga nästlade skills, pil aldrig till container.
7. **Horisontellt:** webbskrap-flode-lr.md + morgonkoll-flode-lr.md (nya LR-referenser,
   original orörda) + LR-default för spec_type flow utan explicit riktning.
- DesignTokens.screenPt: skärm-konstant ikonstorlek (badges 15pt, handtag 26pt).
- Nya tester: V66EdgeMath (4), V66LineEnd (3), V66LegendSkill (2), V66LRFlode (3).
  Unit-sviten: **105/105 gröna.**
- Kvar till v67 (backlog): snap-to-grid, auto-pil vid släpp intill, Flow-läge som
  döljer icke-flödesverktyg, förenkla 3 storlekssystem, header-zon-skydd.

## v65 (deployad till iPhone)

*Tema:* säker autosparning + webbskrap-kedjan (router-vägval kod/MCP/LLM)

**v65 (sim-bevisad: original orört, kopia skapad, ingen tredje fil):**
1. **Autospar skriver aldrig över en öppnad fil.** Öppnad befintlig fil +
   ändringar → sparas som KOPIA med nästa lediga namn ("namn 2.md"), arbetet
   fortsätter i kopian. Oförändrat innehåll → ingenting skrivs. Filer appen
   själv skapat sparas som vanligt. Nytt: `CanvasFileManager.openedExisting`,
   `saveAsCopy`, `nextFreeURL` (strippar siffersuffix: "flöde 2" → "flöde 3");
   baslinje `contentAtOpen` i ContentView (uppdateras vid extern reload).
2. **Ny referens-kedja `webbskrap-flode.md`** (iCloud 1. Mermaid/): skrapa webbsida —
   skill `sidanalys` (hämta rå + identifiera teknisk uppbyggnad) → `steg1-analys.md` →
   ROUTER "Vilket verktyg?" med tre grenar: "statisk html"→kod, "js-renderad"→
   Playwright-MCP, annars→LLM → alla skriver `steg2-data.md` → `leverans` → svar.
   Prompt på ALLA noder (INPUT/UPPGIFT/OUTPUT-nivå) + anteckningar. Första kedjan
   som använder router-vägval enligt SKILL-KEDJA-KONTRAKT.
- Nya tester: `V65AutosparTests` (6) + `V65SkrapFlodeTests` (6, exakta filinnehållet).
  Unit-sviten: **93/93 gröna.**

## v64 (deployad till iPhone)

*Tema:* mindre röra runt formerna — Kims fynd från v63-granskningen

**v64 (sim-bevisad med screenshot, scenario 35):**
1. **ETT connection-handtag** (ersätter de fyra): sitter i högerkanten på vald form.
   Pilen får automatiskt närmaste utgångssida — mindre ikon-röra.
2. **Valbar utgångssida:** nytt fält `EdgeConnection.fromSide` (top/right/bottom/left,
   nil = automatisk). Ändras i pilens meny (tryck-håll mitt-ikonen → "Går ut från").
   Round-trippar: state-JSON `fromSide` + `%% e<i> fromSide:`. Rotations-medveten
   (`sidePoint` i CanvasView).
3. **Tydliga läs-ikoner:** prompt = hjärn-IKON i indigo-cirkel, anteckning = text-IKON
   i gul cirkel (prickarna i v63 var för dolda). Större (18–22pt) + större tap-yta.
- UI-test-helpern `handleTowardCircle` förenklad (bara höger-handtaget finns).
- Nytt sim-scenario: `35-fromside-and-badges`.
- Nya tester: `V64RoundTripTests` (3 st). Unit-sviten: **82/82 gröna.**

## v63 (deployad till iPhone)

*Tema:* Kims sex fynd från v62-granskningen — pil-enhet, pilfärg, gren-kollaps, ikoner, läs-badges

**v63 (alla sex sim-bevisade med screenshots):**
1. **Pil = EN enhet:** linjen slutar bakom spetsbasen (11pt-inset), spets + linje ritas i
   samma SOLIDA färg (tidigare 0.7/0.85-opacity → strecket lyste igenom spetsen).
2. **Pilfärg:** `EdgeConnection.colorHex` — välj i pilens meny (tryck-håll mitt-ikonen →
   "Färg på pilen", 8 färger). Round-trippar (state-JSON `color` + `%% e<i> color:`).
3. **Kollaps PER GREN:** `collapsedEdgeIds` ersätter nod-kollaps — minus-badgen kollapsar
   BARA den pilens efterföljare; syskon-grenar står kvar. `descendantsFromBranch`-logiken
   används äntligen. Migration: gamla filer med `"collapsed": [nod]` / `%% nod collapsed`
   → nodens alla utgående grenar. Persist: `"collapsed": true` på kanten + `%% e<i> collapsed: true`.
4. **Handtag utanför hörnen:** SelectionHandles offsetas ut (margin 18pt, rotation 36→48 full).
5. **Läs-badges:** indigo hjärn-prick (prompt) toppvänster + gul prick (anteckning) topphöger →
   tap = `QuickReadSheet` (read-only, växer med texten, Redigera-knapp). Nya filer:
   PromptBadge.swift + QuickReadSheet.swift.
6. **Kollaps-badges separerade:** minus 16pt vinkelrätt från linjen (bort från midpoint-ikonen);
   plus-stubbar solfjäder-sprids (±0.5 rad) när flera grenar kollapsats från samma nod, stub 50→62pt.
- Nya tester: `V63RoundTripTests` (6 st: pilfärg båda vägarna, gren-kollaps, efterföljare,
  round-trip per gren, migration ×2). Unit-sviten: **79/79 gröna.**
- **Observerat (ej åtgärdat):** IMG_0552 visade halv svart skärm i landskap — verifieras separat.

## v62 (deployad till iPhone)

*Tema:* Kims tre fynd från v61.2-granskningen — pilspetsar, etikettplacering, separat färg

**v62:**
- **Pilspets-fix (kritisk):** spetsen följer nu den SYNLIGA linjens riktning vid änden
  (bezier-tangent t=0.92/0.08 på faktiska kontrollpunkter, inkl. obstacle-routade).
  v60 hade låst vinkeln till sidans normal → skeva spetsar på diagonala pilar.
  Visuellt verifierad i sim (förstorad screenshot av båda gren-pilarna).
- **Kant-etikett ovanför/under:** nytt fält `labelPlacement` (above/below, default below),
  segmented-val i Pil-text-sheeten, round-trippar via state-JSON + `%% e<i> labelPlacement:`.
  Demo-filerna har nu både "ja" och "nej" på grenarna.
- **Separat fyllnings- och ram-färg:** `strokeColorOverride` per form; färg-raden har
  segmenten **Paket | Fyllning | Ram** (swatchar + ta bort-chip). Egen fyllning ger
  automatiskt svart/vit text via luminans. `colorOverride` påverkar nu även renderingen
  i appen (tidigare bara exporten). Round-trip: state-JSON `strokeColor` + `%% stroke:`.
- Nya tester: `V62RoundTripTests` (5 st). Unit-sviten: **73/73 gröna.**

## v61.2 (deployad till iPhone)

*Tema:* Skill-kedjor — slutmålet: rita flöde → kedja av Claude Code-skills

**v61.2:**
- **Parser: subgraph-medlemskap → `childOfContainerId` i fallback.** Utan den såg
  edge-routingen containern som hinder för barnens pilar → pilarna svepte långt åt
  sidan. Nu raka pilar genom container-gränser. Test: `V61KedjeFilTests` (68/68 gröna).
- **Nytt koncept levererat + testat på riktigt:**
  - `SKILL-KEDJA-KONTRAKT.md` — container = skill, violett memory-nod = överlämnings-fil,
    prompt per nod = subagent-instruktion.
  - Skill `~/.claude/skills/flode/` — "kör flödet X" / "bygg skills av flödet".
  - Referens-kedja `morgonkoll-flode.md` (iCloud): mejl-svep → steg1-mejl.md →
    sammanfatta → steg2-sammanfattning.md → rapport → svar i chatten.
  - **E2E-körd på riktigt:** 20 Gmail-trådar → 3 filer i `morgonkoll/` → färdig
    morgonrapport. Visuellt verifierad i simulatorn (screenshots).

## v61.1 (deployad till iPhone)

*Tema:* Öppna-fil-buggen Kim hittade — vyn centrerar nu på innehållet

**v61.1:**
- **"Demon gick inte att öppna" = vyn stod på canvas-mitten (1500,1500) medan Claude-ritade
  former låg på (115–285, 160–670)** → tomt vitt papper. Fix: `openFile` centrerar vyn på
  innehållets mittpunkt; live-reload centrerar BARA om inget innehåll syns (stör inte mitt i arbete).
- `centerOnPoint` flyttad CanvasView `@State` → ContentView-ägd `@Binding` (jump-links opåverkade).
- **Visuellt verifierad i simulatorn** (idb): demo-filen öppnad via Files-pickern → lagrad
  TD-layout, kategorifärger, "ja"-etikett, allt centrerat. Screenshot-bevisad.
- Nytt test: `V61DemoFileTests` (demo-filens exakta innehåll → 5 former/4 kanter/layout-ordning).

## v61 (2026-06-05)

*Tema:* "Ren mermaid i backend" — gap-analys + Claude→Kim-riktningen fixad (natt-session)

**v61 (denna session — 4 granskar-agenter + adversarial verifiering, se `GAP-ANALYS-v61.md`):**
- **Rå mermaid från Claude → riktigt flödesschema.** Ny `MermaidAutoLayout`: lagrad
  BFS-layout som följer `flowchart TD/LR/BT/RL`. Cirkel-placeringen borta.
- **Mermaid-blocket självbärande.** Ny `MermaidMetaComments`: fallback-parsern läser nu
  ALLA `%%`-kommentarer (pos, size, rot, width/height, color, pack, style, note, prompt,
  name, hidden-label, collapsed, link, table, line-end) → full round-trip utan state-JSON.
- **Claude-typisk syntax stöds:** inline-kanter (`a["X"] --> b["Y"]`), ocitate labels
  (`a[X]`), nakna id:n (`A --> B`), `==>`, `-- text -->`, `subgraph id` utan label,
  `:::kategori`-suffix utan fantomnoder.
- **iCloud-säker live-reload:** `FileChangeObserver` (NSFilePresenter) + innehålls-hash;
  datum-polling kvar som fallback. Claudes ändringar syns utan omöppning.
- **1-tryck "Kopiera Mermaid-kod"** i Lägen-menyn + pil-tips i tom-canvas-hinten (UX-009 delvis).
- **`N8N-FLODE-KONTRAKT.md`:** kategori→n8n-nodtyp, kantetikett→villkor, prompt→trigger —
  Claude bygger workflow/skill utan gissningar. Refereras i CLAUDE.md.
- Nya tester: `V61FallbackParserTests` (13) + `V61LiveReloadTests` (2). Unit-sviten grön.
- **41 gamla UI-tester lagade** (commit 544c5fa — föråldrade efter v50.2/v60: porträtt-launch-arg,
  riktningsspecifika `connection.handle.*`, scenario-launch i stället för syntetiska drag).
  Full svit: 66/66 unit + 107/111 UI i en sittning; de 4 (V48) är ordnings-flaky — 15/15 gröna
  isolerat, direkt efter V46:s 30 utforskningstester kan 3–4 tima ut. Ingen app-regression.
- **Kvar:** Kims verifiering på iPhonen (v61-punkterna i ARKITEKTUR-MERMAID.md + v60.1:
  forcerad landskap, container-känsla). Backlog: nice-to-have-listan i `GAP-ANALYS-v61.md`.
  Demo-fil att öppna: `v61-demo-från-claude.md` i iCloud-Mermaid-mappen.

## v60.1 (deployad)

*Tema:* Buggsvep efter v60 — forcerad rotation + container-barn (äkta idb-verifiering)

**v60.1 (denna session — idb installerat, riktig sim-utforskning):**
- **Forcerad landskap fixad (svart nedre halva på enhet / sidledes i sim):** root cause var att
  SwiftUI `WindowGroup` inte lät orienteringslåset gälla + tvetydig `.landscape`-mask i
  `requestGeometryUpdate`. Fix: UIKit-livscykel (`main.swift` + `AppDelegate`/`SceneDelegate` +
  `OrientationLockedHostingController`), explicit scene-manifest, konkret `.landscapeRight`.
  Autosave hårdad mot `didEnterBackground`. Verifierat i sim via idb (full landskap + vänster-sidebar).
- **Container-barn följer nu med vid flytt:** `claimChildren` körs när containern väljs → barn får
  explicit `childOfContainerId` → tappas inte mitt i en flytt. Verifierat via idb.
- **Verifierat som redan fungerande** (via idb): container-look (C), namnbyte (D), prompt/namn (G),
  8-form-rad (F), rak pil-entré även diagonalt (A), rundad processpil (B).
- Nytt regressionstest (`OrientationTests`) → 49/49 gröna. Full rapport: `BUGSVEP-v60.md`.
- **Kvar:** Kim bekräftar forcerad landskap + container-känsla på sin iPhone.

**v60 (föregående session — multi-agent-konsensus):**
- **A — beroende-pilar möter rakt:** `outwardNormal` är nu rotations-medveten + pilhuvudet pekar längs sidans inåt-normal → pilen går in vinkelrätt (även diagonalt/roterat), inte snett.
- **B — processpilens spets rundad** (höger spets), i både form och chip, med degenerations-cap.
- **C — container i Lucidchart-stil:** solid header-rad med titel + ljus kropp + tunn ram (canvas + chip).
- **D — container valbar/namnbar:** containrar z-ordnas under barn → tap/namnbyte fungerar.
- **E — container-barn följer alltid med:** `childOfContainerId` sätts vid skapande + container "adopterar" former vid släpp; barn följer vid flytt.
- **F — alla 8 geometriska former på översta raden** (40pt, ≥44pt tap) + **landskap = vänster vertikal sidebar** (adaptiv layout, äkta orientering).
- **G — prompt + namn per form (n8n):** nytt `prompt`-fält (EditShapeSheet), namn = label; båda exporteras i Mermaid-koden (`%% name:` / `%% prompt:`) för att kopiera flöden till n8n. Round-trippar.
- Test-target: nya tester (kant, prompt, octagon) + snapshots omrecordade. Hela sviten grön.

> **Verifiera på iPhone:** landskaps-sidebaren (kan ej rotera simulatorn via script), container drag/resize-känsla, diagonala pilar.

**v51.2 (föregående):**

*Tema:* Landskapsläge (punkt 6) — äkta orientering

**v51.2 (denna session):**
- **Skärmläge porträtt/landskap** i Lägen-menyn ("Skärmläge"). Äkta orientering via `AppDelegate` + `requestGeometryUpdate` (iOS 16+) — UIKit roterar hela koordinatsystemet så drag-släpp, UIScrollView-pan/zoom, sheets och tangentbord följer med korrekt. Valet sparas (`@AppStorage`).
- Avvisade "rotera ikonerna 90°"-idén (enhällig panel: skulle desynka drag/scroll/sheets/tangentbord). Med äkta orientering behövs ingen ikon-rotation — allt står rätt.
- `project.yml`: låste upp Landscape Left/Right. Ny `Orientation.swift`.
- Verifierat i sim (roterar utan krasch, porträtt default). **Slutlig känsla (drag/zoom i landskap) verifieras på iPhone.**

**v51.1 (föregående):**

*Tema:* Åttahörning + chip-omordning (punkt 5)

**v51.1 (denna session):**
- **Ny form: åttahörning (octagon)** med rundade hörn (`OctagonShape`), bas 80×80. Round-trippar förlustfritt via state-JSON (`type: "octagon"`); Mermaid-syntax-fallback = rundad rektangel.
- Hanterad i alla form-switchar (kompilator-verifierat) + de tysta `default`-fällorna i `ShapeGeometry` (explicit 80×80).
- **Chip-raderna omordnade** (rundade först): Rad A = cirkel, pill, rektangel, kvadrat, container; Rad B = diamant, processpil, åttahörning, tabell, länk, linje, anteckningar. Chip-blocken refaktorerade till `geoChip`-helper (DRY).

**v51.0 (föregående):**

*Tema:* Dark mode — beroende-pilarna syns nu (punkt 4)

**v51.0 (denna session):**
- **Dark mode-fix:** kanter/pilar/etiketter var osynliga i iPhone dark mode (ritades med `.primary` = vit, mot canvasens fasta vita papper). Canvasen är medvetet ett vitt ritbräde (ColorPack-färger + Mermaid-export är ljusa), så lösningen är `.environment(\.colorScheme, .light)` på hela canvas-subträdet → allt bläck blir mörkt och syns i båda lägena. Toolbar/menyer förblir adaptiva.

**v50.9 (föregående):**

*Tema:* Form-polish (punkt 1–3 av Kims lista)

**v50.9 (denna session):**
- **ProcessArrow** ("pilen") rundare hörn: `processArrowCornerRadiusRatio` 0.18→0.30 (spetsen kvar skarp; extra höjd-cap mot degenerering vid platt resize).
- **Diamant** lite rundare: `diamondCornerRadiusRatio` 0.075→0.10 (chip+canvas via delad token).
- **Cirkel-chippen** ritas nu som riktig `Circle()` via `iconSize` — matchar övriga chips storlek (var för liten som SF Symbol).

**v50.8 (föregående):**

*Tema:* Chip ↔ canvas — äkta single source (formerna matchar på riktigt)

**v50.8 (denna session):**
- **Grundfix:** `DesignTokens` enade tidigare bara hörn-radie + stroke — **inte aspect ratio**. Chip-ikonernas storlekar var hårdkodade oberoende av canvas → glidning ("åter igen").
- Chip-ikonernas **storlek härleds nu från canvas** (`Chip.iconSize(for:)` läser `ShapeGeometry`-bas-ratio) → chip och canvas kan aldrig divergera i proportion.
- **Alla** hörn-radier uttrycks som ratio (`Shape.cornerRadius(for:height:)`); canvas slutade hårdkoda 14/16 och stroke 1,5 → läser tokens.
- **Diamant**: `DiamondShape` bytte absolut hörn-radie → ratio (missades i v50.5). Chip var knubbig (30% rundning), canvas vass (7,5%) — nu samma proportion.
- Rättat pill-ratio (1,625, inte 1,875) och **reverterat v50.7 UX-012-regressionen** (rektangel 2,0 → 1,5).
- `ComponentGallery` (chip vs canvas-jämförelse) läser nu samma källa → sann jämförelse.

**v50.7 (föregående):**
- **UX-004** — kaskad-offset på nya former (slutar stapla osynligt; 4/6 personas).
- **UX-005** — mjuk markerings-outline direkt vid tap (syntes tidigare först vid drag).
- **UX-001/007/010/013** — läsbara VoiceOver-labels på toolbar-knappar, form-chips och resize/rotation-handtag (läste tidigare råa SF Symbol-namn).
- **UX-006** — ≥44pt träffytor på collapse-badge och 100%-zoomknapp (visuell storlek oförändrad).
- **UX-003** — tomt-tillstånd (`EmptyCanvasHint`) vägleder förstagångsanvändare.
- **UX-012** — rektangel-chip tydligare avlångt (skiljs från kvadrat).
- **Verifierat icke-buggar (ingen ändring):** UX-002 (undo korrekt per-steg), UX-008 (drag funkar på omarkerad form; snabbsvep = scroll by design), UX-014 (kosmetiskt animations-kantfall).
- **Follow-up (kräver design):** UX-009 (pil-upptäckbarhet), UX-011 (tabell-redigerings-affordance).
- Arkitektur-doc omskriven: `ARKITEKTUR-MERMAID.md` speglar nu v50.7 (var v39). v39 arkiverad.

**v50.6 (föregående):**
- **6 buggar fixade** (hittade via parallell Claude Code CLI-bugjakt + sim-agenter):
  - BUG1 (missionskritisk): `-->` i nodtext/notis trunkerade JSON-state-blocket → all fidelity tappades. Fix: matcha `\n-->`.
  - H1/H2: tabell med 0 rader/kol kraschade. Fix: `max(1,…)`-klamp.
  - M1: container hoppade till 2,4× vid resize-handtag. Fix: typ-specifik bas.
  - M3: long-press popade meny i edge-mode. Fix: `guard !edgeMode`.
  - F11: minus-badge överlappade marker-handle. Fix: min 55pt offset.
  - F13: haptic feedback på long-press.
  - 2 regressionstester (RoundTripTests): `-->` i text + 0-rader-tabell.
- **Nytt verktyg: `ux-personas-test` (v1.0)** — AI-testanvändare (6 personas) driver
  appen i simulatorn via **idb** och hittar UX-fel + förbättringar. Smart-prompt-lager
  expanderar korta svenska fraser till rika testuppdrag. Ligger i `~/.claude/skills/`.
- **Första UX-svep:** `UX_PERSONA_AUDIT.md` — 14 unika fynd (0 krascher). Topp-3:
  former staplas osynligt, ingen markeringsfeedback, blockerande nybörjarbuggar.

> **OBS dokumentationsdrift:** `ARKITEKTUR-MERMAID.md` speglar v39 och historiken nedan
> stannar vid v34. Koden har gått till v50.6 via många små iterationer utan full
> arkitektur-omskrivning. En full ARKITEKTUR-uppdatering är en egen framtida uppgift.

---

## Tidigare: v34 (under utveckling)

**Tema:** Canvas-omtag + modulär arkitektur

- UIScrollView-baserad canvas (löser drop/pan/zoom-buggar)
- Fast 4000×4000pt canvas (Microsoft Whiteboard-stil borttagen för MVP)
- Minimap bortplockad (med fit-zoom som min behövs den inte)
- Apple `.dropDestination` ersätter manuell ShapeDragController
- Apple `.draggable` ersätter manuell DragGesture-controller
- AppVersion: v34 (bumpa från v34-wip vid release)

## v33 (released)

- 44pt-knappar enligt Apple HIG
- Haptic feedback vid drop + toolbar-toggle
- Smooth spring-animation vid toolbar expand/collapse
- markerButton flyttad till Lägen-menyn
- V33VersionVisibleTests bevisar att "v33" syns i UI

## v32 / v31 (released)

Se `arkiv/ARKITEKTUR-MERMAID-v32.md` och `arkiv/ARKITEKTUR-MERMAID-v31.md` för detaljer.

## Bakåt: v25 - v30

Se `arkiv/ARKITEKTUR-MERMAID-v25.md` till v30 för historia.

## v50 (under utveckling)

**Tema:** Visuell placerings-bugjakt + 2 root-cause-fixar

- **Ny test-infrastruktur:** `UITests/V50PlacementTests.swift` + `UITests/V50PlacementMatrix.md`
  + `Sources/App/UITestScenarios.swift` — 23 deterministiska scenarier byggs
  via `-uitest-place-*` launch-args, screenshot per scenario, granskning post-hoc
- **F-02 fix:** Pilar mellan barn i en container gick rakt upp ur skärmen.
  Container sågs som obstakel av routing-algoritmen även för pilar mellan
  dess egna barn. Fix i `CanvasView.drawEdge` + ny `edgeAnchors` — hoppa över
  container när from/to har `childOfContainerId == container.id`.
- **F-03 fix:** Midpoint-handle och kant-etikett saknades på böjda bezier-pilar.
  Mid beräknades som rak mid mellan endpoints → hamnade inuti obstaklet.
  Fix: ny `EdgeAnchors`-helper räknar mid + tangent vid bezier t=0.5.
- Fullständig rapport: `UI-PLACERINGS-FYND-v49.md`

## v49 (released)

- Multi-agent-konsensus-metod för pilspets-asymmetri + minus-badge-state
- Launch-arg-baserade test-scenarier för visuell verifiering

## Framåt

**All framåtblick ligger i `PROJEKTPLAN.md` (lagen, regel 13 i CLAUDE.md).**
Denna fil är ren version-HISTORIK. Gamla backlog-idéer (collaborative cursors,
monolit-splittning, infinite canvas, MVP2) ligger kvar som kandidater för
PROJEKTPLAN.md:s idébank — de byggs inte härifrån.

## Filer

- `CLAUDE.md` — konstitutionen, läses först
- `PRODUKT.md` — produktvision
- `ARKITEKTUR-MERMAID.md` — aktuell arkitektur (uppdateras per release)
- `ARKITEKTUR-SWIFT.md` — modulstruktur (uppdateras per release)
- `ROADMAP.md` — denna fil
- `VERSIONSHANTERING.md` — deploy-checklista
- `MERMAID-FAKTA.md` — Mermaid-syntax-referens
- `METOD-VISUELL-DIALOG.md` — protokoll för visuellt språk Kim ↔ Claude Code
- `Start för ios appar Kim.md` — iOS-deploy
- `arkiv/` — versionshistorik
