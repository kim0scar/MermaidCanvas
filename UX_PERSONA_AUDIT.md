# UX-Persona Audit (v1.0 full svep) — 2026-05-30

## Sammanfattning
- **Personas:** P1 nybörjare, P2 stressad, P3 nyfiken/edge, P4 Kim (visuell/dyslexi), P5 Apple-designgranskare, P6 tillgänglighet — alla 6.
- **Läge:** UTFORSKA | **Sim:** iPhone 17-familjen, iOS 26.4 | **Motor:** idb
- **Råfynd:** 24 → efter dedup: **14 unika** + 2 positiva
- **Severity:** 3 HÖG, 8 MEDEL, 3 LÅG | 7 buggar, 7 förbättringar
- **Inga krascher** under hela svepet (BUG1 `-->` och H1/H2 0-rader redan fixade håller).

**Apple-nivå-omdöme:** Grunden är god — toolbar-layouten är proffsig (jämn 52pt-spacing) och appen är stabil. Men tre saker drar ner den från Apple-nivå: (1) **tillgänglighet** är svag — VoiceOver läser tekniska symbolnamn, handtag saknas i a11y-trädet; (2) **feedback** — markering syns inte direkt, former staplas osynligt; (3) **upptäckbarhet** — nybörjare hittar inte pilar och får ingen onboarding. Ingen av dessa är svår att fixa.

---

## HÖG

### UX-001 [BUGG] VoiceOver läser tekniska symbolnamn istället för begripliga labels
- **Sett av:** P6 (+ P1 om ikon-otydlighet) | Linser: a11y-labels, ikon-begriplighet
- **Vad:** Toolbar-knappar exponerar råa SF Symbol-namn ("swatchpalette", "paintpalette", "rectangle.dashed", "bubble.left.and.text.bubble.right") och chips läses som "chip circle". VoiceOver blir obrukbart.
- **Var:** Toolbar + chip-rad
- **Repro:** Kör a11y-träd → AXLabel = symbolnamn/id
- **Bevis:** screenshots/P6/01-selected.json
- **Severity:** HÖG | **Tagg:** BUGG

### UX-002 [BUGG] Undo tömmer hela canvasen istället för ett steg i taget
- **Sett av:** P2 (KANDIDAT — verifiera) | Lins: "gör undo det jag tror?"
- **Vad:** Efter 3 skapade former tog 2× Undo bort ALLA tre. Ångrar man en sak kan man förlora allt.
- **Var:** Undo-knappen
- **Repro:** Skapa 3 former → Undo ×2 → canvas tom
- **Bevis:** screenshots/P2/04-undo-twice.png
- **Severity:** HÖG | **Tagg:** BUGG — *verifiera repro innan fix (kan vara att 3 chip-tap = 1 batchad operation)*

### UX-003 [BUGG] Ingen onboarding / tomt-tillstånd när canvasen är tom
- **Sett av:** P1 (KANDIDAT) | Lins: tomt-tillstånd
- **Vad:** Tom canvas ger ingen vägledning. Nybörjare vet inte att man trycker "Shape" för att börja.
- **Var:** Startskärm, tom canvas
- **Repro:** Öppna appen → tom yta, ingen hint
- **Bevis:** screenshots/P1 (start)
- **Severity:** HÖG | **Tagg:** BUGG (blockerar förstagångsanvändning)

---

## MEDEL

### UX-004 [FÖRBÄTTRING] Nya former staplas i exakt samma punkt *(starkast signal — 4 personas)*
- **Sett av:** P1, P2, P4, P5 (BEKRÄFTAT 4/6) | Linser: effektivitet, polish, hierarki
- **Vad:** Varje ny form hamnar pixel-exakt i center → oläslig hög, ser ut som bugg. Apple-appar kaskad-offsetar.
- **Repro:** Skapa 2-3 former → identisk position
- **Bevis:** screenshots/P2/02-rapid-create.png, P5/02-twoshapes.png
- **Severity:** MEDEL (höjd från LÅG pga 4 personas) | **Tagg:** FÖRBÄTTRING

### UX-005 [BUGG] Markering ger ingen tydlig visuell återkoppling
- **Sett av:** P1, P4, P5 (BEKRÄFTAT 3/6) | Linser: feedback, tydlighet, Apple-känsla
- **Vad:** Markerad form saknar mjuk highlight — handtag syns först vid drag. Oklart vad som är valt.
- **Repro:** Tap en form → ingen omedelbar markeringsindikering
- **Bevis:** screenshots/P4, P5/02-twoshapes.png
- **Severity:** MEDEL | **Tagg:** BUGG

### UX-006 [BUGG] Träffytor under 44pt (handtag, badges, "100%"-knapp)
- **Sett av:** P4, P6 (BEKRÄFTAT 2/6) | Lins: träffyta, motorik
- **Vad:** Resize/rotations-handtag ~29pt, edge-badges 31-36pt, "100%"-zoomknapp 40×28pt — alla under Apples 44pt.
- **Repro:** Mät frames i a11y-träd / markera form
- **Bevis:** screenshots/P6/01-selected.json, P4
- **Severity:** MEDEL | **Tagg:** BUGG

### UX-007 [BUGG] Resize-/rotations-handtag saknas helt i a11y-trädet
- **Sett av:** P6 | Lins: saknade labels
- **Vad:** Handtag + badges syns visuellt men finns inte i accessibility-trädet → osynliga för VoiceOver.
- **Bevis:** screenshots/P6/02-sel-try.png
- **Severity:** MEDEL | **Tagg:** BUGG

### UX-008 [BUGG] Drag på omarkerad form gör inget (kräver tap först)
- **Sett av:** P2 (KANDIDAT) | Lins: gesture-konflikt
- **Vad:** Stressad användare drar reflexmässigt → inget händer, tror appen hänger. Behöver visuell hint.
- **Repro:** Skapa form → swipe direkt → ingen förflyttning
- **Bevis:** screenshots/P2/03-drag-top.png
- **Severity:** MEDEL | **Tagg:** BUGG (eller medvetet designval → gör tydligt)

### UX-009 [FÖRBÄTTRING] Nybörjare hittar aldrig hur man skapar en pil
- **Sett av:** P1 (KANDIDAT) | Lins: upptäckbarhet
- **Vad:** Pil-skapande (connection-handle) upptäcktes aldrig av nybörjar-personan. Kärnfunktion dold.
- **Bevis:** screenshots/P1
- **Severity:** MEDEL | **Tagg:** FÖRBÄTTRING

### UX-010 [FÖRBÄTTRING] Toolbar-ikoner kommunicerar inte sin funktion
- **Sett av:** P1 (+ relaterar till UX-001) | Lins: ikon-begriplighet
- **Vad:** "Shape", "swatchpalette", "paintpalette" m.fl. säger inte vad de gör för en förstagångsanvändare. Inga labels/tooltips.
- **Bevis:** screenshots/P1, P5/01-toolbar.png
- **Severity:** MEDEL | **Tagg:** FÖRBÄTTRING

### UX-011 [FÖRBÄTTRING] Tabell-redigering (rader/kolumner) är svårupptäckt
- **Sett av:** P3 | Lins: upptäckbarhet
- **Vad:** chip.table skapar tabell men hur man ändrar rader/kol är inte uppenbart.
- **Bevis:** screenshots/P3/02-table-tap.png
- **Severity:** MEDEL | **Tagg:** FÖRBÄTTRING

---

## LÅG

### UX-012 [FÖRBÄTTRING] chip.rectangle och chip.square nästan visuellt identiska
- **Sett av:** P4, P5 (BEKRÄFTAT 2/6) | Lins: konsistens/distinkthet
- **Vad:** De två chipsen är förväxlingsbara på en blick.
- **Bevis:** screenshots/P5/01-toolbar.png
- **Severity:** LÅG | **Tagg:** FÖRBÄTTRING

### UX-013 [FÖRBÄTTRING] Chips läses som "chip circle" av VoiceOver
- **Sett av:** P6 | Lins: a11y-label
- **Vad:** chip.* har id men ingen separat människo-label. (Delmängd av UX-001, men egen fix.)
- **Severity:** LÅG | **Tagg:** FÖRBÄTTRING

### UX-014 [BUGG] Övergående a11y-glitch: chips delar koordinat mitt i animation
- **Sett av:** P3 | Lins: timing/animation
- **Vad:** Under chip-radens in-animation rapporterades square/diamond på samma koordinat en kort stund. I vila korrekt åtskilda (52pt). Kantfall.
- **Bevis:** screenshots/P3/01-table.json
- **Severity:** LÅG | **Tagg:** BUGG (lågprio)

---

## Positiva fynd (Apple-nivå redan)
- **Stabilt:** inga krascher under hela svepet, inkl. tabell, lång text, snabba sekvenser (P3).
- **Toolbar-spacing:** chip-raden har exakt jämn 52pt-rytm — proffsig layout (P5).

## Kandidater (1 persona — verifiera repro)
UX-002 (undo), UX-003 (onboarding), UX-008 (drag-kräver-tap), UX-009 (pil-upptäckbarhet).

---

## Topp-3 att fixa först
1. **UX-004 staple-bugg** — sågs av flest (4/6), enkel fix (kaskad-offset på nya former), stor synlig vinst.
2. **UX-005 markeringsfeedback** — 3/6, lyfter hela "känslan" mot Apple-nivå (mjuk highlight vid tap).
3. **UX-001 VoiceOver-labels** — enda HÖG som är säker (ej kandidat); gör appen användbar för synskadade.

## Rekommenderad väg per fynd
- **Buggar (UX-001,002,005,006,007,008,014):** kör `multi-agent-bug-fix` (3-agent konsensus + verifiering).
- **iPhone-grind:** UX-006 (träffytor) + UX-005 (feedback) + UX-008 (drag) rör gester/känsla → verifiera på Kims iPhone via `ui-verifiering-ios` innan de släpps.
- **Förbättringar (UX-004,009,010,011,012,013):** designbeslut — ta i prioritetsordning, sim räcker för verifiering.
