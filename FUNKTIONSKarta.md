# 🗺️ FUNKTIONSKARTA — Visuali2e (MermaidCanvas)

Genomgångsdokument för **alla menyer och funktioner** i appen. Tänkt att du går igenom
yta för yta och bockar av att varje funktion *sitter rätt, ser rätt ut, funkar, och behövs*.

En tabell per yta (rubriken = **var den nås**). Rad = en funktion. Du fyller i bockrutorna själv.

---

## ✅ Maskin-kontroll 2026-06-22 (MB Steg 1)

138 funktioner auditerade — 16 ytor × 4 dim, 51 sub-agenter, varje fynd adversariellt verifierat.
- **Me (Mermaid) bevisat:** 199 enhetstester · conformance 3/3 · render 3/3 · arch-check — alla gröna.
- **23 fynd bekräftade** (🔴 1 hög · 🟠 8 medel · 🟡 14 låg) → se **`KONTROLL-FYND.md`**. 12 falska larm motbevisades.
- Maskin-dimensionerna (Me/Ber/Plats) gröna **utom** de 23 fynden. **UI-känsla på riktig enhet = din iPhone-bock** (⬜ kvar med flit).

---

## Teckenförklaring (de fyra kontrollerna)

| Kolumn | Vad du kollar |
|---|---|
| **Me** | **Mermaid** — funktionen exporteras/round-trippar korrekt i mermaid-koden (rita → kopiera → klistra → exakt samma). **–** = funktionen rör inte mermaid (ren UI-knapp). |
| **UI** | **Utseende** — ser rätt och snyggt ut i menyn och på canvas (ikon + etikett stämmer, inget trasigt). |
| **Ber** | **Beroenden** — funkar ihop med det den kräver/påverkar (t.ex. Färg kräver markerad form; Pil kräver två former). Inga krockar. |
| **Plats** | **Placering & behov** — rätt meny, rätt plats, inom kant, nåbar — **och behövs** (ingen död/dubblerad funktion). |

Bock: `⬜` = ej kontrollerad · `✅` = OK · `⚠️` = problem (skriv i **Not.**). · `–` = ej aktuellt.

---

## 📑 Innehåll

**Verktygsraden**
1. [Huvudrad](#1-verktygsrad--huvudrad)
2. [Former-rad](#2-verktygsrad--former-rad)
3. [Färg-rad](#3-verktygsrad--färg-rad)
4. [Text-rad](#4-verktygsrad--text-rad)
5. [Formpaket-rad](#5-verktygsrad--formpaket-rad)
6. [Markera-flera-rad](#6-verktygsrad--markera-flera-rad)
7. [Lägen-meny](#7-verktygsrad--lägen-meny)

**Canvas (direkt på ytan)**
8. [Form-gester](#8-canvas--form-gester)
9. [Anslutningsprickar (rita pil)](#9-canvas--anslutningsprickar-rita-pil)
10. [Pil-meny](#10-canvas--pil-meny)
11. [Form-långtrycksmeny](#11-canvas--form-långtrycksmeny)
12. [Läs-lapp (NoteCard)](#12-canvas--läs-lapp-notecard)
13. [Brödsmulor (Visio-drill)](#13-canvas--brödsmulor-visio-drill)
14. [Handtag + markeringsläge](#14-canvas--handtag--markeringsläge)
15. [Övrigt på canvas](#15-canvas--övrigt)

**Fönster**
16. [Sheets / dialoger](#16-sheets--dialoger)

**Status**
17. [Kvarstår / att bygga](#17-kvarstår--att-bygga)

---

## 1. Verktygsrad – Huvudrad

*Var: Verktygsrad, alltid synlig (topp-bar i porträtt, vänster sidebar i landskap).*

| Funktion | Vad den gör | Me | UI | Ber | Plats | Not. |
|---|---|:--:|:--:|:--:|:--:|---|
| Former-knapp | Öppnar/stänger Former-raden där du väljer form att lägga till. | – | ⬜ | ⬜ | ⬜ |  |
| Formpaket-knapp | Öppnar/stänger Pack-raden (UI- och Skillflöde-paket). | – | ⬜ | ⬜ | ⬜ |  |
| Färg-knapp | Öppnar Färg-raden (släckt tills en form är markerad). | – | ⬜ | ⬜ | ⬜ |  |
| Textstil-knapp | Öppnar Text-raden (släckt tills en form är markerad). | – | ⬜ | ⬜ | ⬜ |  |
| Zoom-bricka | Visar zoom i %; tryck nollställer till 100 %. | – | ⬜ | ⬜ | ⬜ |  |
| Ångra | Ångrar senaste ändringen. | – | ⬜ | ⬜ | ⬜ |  |
| Gör om | Gör om en ångrad ändring. | – | ⬜ | ⬜ | ⬜ |  |
| Lägen-meny | Öppnar Lägen-menyn (fil, kod, export, mallar m.m.). | – | ⬜ | ⬜ | ⬜ |  |

---

## 2. Verktygsrad – Former-rad

*Var: Verktygsrad → Former. Varje chip: tryck = lägg i mitten, dra = släpp där du vill.*

| Funktion | Vad den gör | Me | UI | Ber | Plats | Not. |
|---|---|:--:|:--:|:--:|:--:|---|
| Cirkel | Lägger till en cirkel. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Kapsel | Lägger till en avlång form med helt rundade ändar. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Rektangel | Lägger till en rektangel. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Kvadrat | Lägger till en kvadrat med rundade hörn. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Romb | Lägger till en romb (beslutssteg). | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Processpil | Lägger till en processteg-pil (rektangel med spetsig högerände). | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Åttahörning | Lägger till en åttahörning (octagon). | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Triangel | Lägger till en liksidig triangel. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Container | Lägger till en grupperande behållare (Mermaid-subgraf) som former kan ligga i. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Tabell | Lägger till en tabell. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Länk | Lägger till en hopplänk som kan peka vidare. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Linje | Lägger till en lös, fristående linje utan pilhuvud. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Notis | Öppnar anteckning-popupen som visar all text på canvasen. | – | ⬜ | ⬜ | ⬜ |  |
| Emoji | Lägger till en naken emoji (😀) som byts genom att skriva valfri emoji. | ⬜ | ⬜ | ⬜ | ⬜ |  |

---

## 3. Verktygsrad – Färg-rad

*Var: Verktygsrad → Färg (kräver markerad form). Överst en väljare för **vad** färgen gäller.*

| Funktion | Vad den gör | Me | UI | Ber | Plats | Not. |
|---|---|:--:|:--:|:--:|:--:|---|
| Väljare: Paket | Färgvalet byter hela formens paket (fyllning + ram + text). | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Väljare: Fyllning | Färgvalet ändrar bara fyllningsfärgen. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Väljare: Ram | Färgvalet ändrar bara ramfärgen. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Paket: Ingen färg | Tar bort paketet → vit form med standardram. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Paket: Persika / Rosa / Blå / Grön / Gul / Lila | Färglägger formen med pastell-paketet. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Paket: UI Blå / UI Grön / UI Röd (knapp) | Kraftig iOS-färg med vit text (för UI-knappar). | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Paket: UI Grå (yta) / UI Mörk (navbar) | Grå yta / mörk navbar-yta. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Fyllning/Ram: Ta bort egen färg | Nollställer egen fyllning/ram → följer paketet igen. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Fyllning/Ram: Färgprick | Sätter formens fyllning eller ram till vald färg (palett av alla pakets färger + grå/mörk/vit). | ⬜ | ⬜ | ⬜ | ⬜ |  |

---

## 4. Verktygsrad – Text-rad

*Var: Verktygsrad → Textstil (kräver markerad form). Gäller den markerade formens text.*

| Funktion | Vad den gör | Me | UI | Ber | Plats | Not. |
|---|---|:--:|:--:|:--:|:--:|---|
| Textstorlek → Rubrik 1 | Stor rubrik (fet, 20 pt). | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Textstorlek → Rubrik 2 | Mellanstor rubrik (halvfet, 17 pt). | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Textstorlek → Rubrik 3 | Liten rubrik (medium, 14 pt). | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Textstorlek → Brödtext | Vanlig brödtext (normal, 13 pt). | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Fet | Växlar texten mellan fet rubrik och brödtext. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Punkter | Slår på/av punktlista (stänger av numrerad). | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Numrerad | Slår på/av numrerad lista (stänger av punkter). | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Vänster / Centrera / Höger | Justerar texten i formen. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Indrag– / Indrag+ | Minskar/ökar textens indrag ett steg (0–3). | ⬜ | ⬜ | ⬜ | ⬜ |  |

---

## 5. Verktygsrad – Formpaket-rad

*Var: Verktygsrad → Formpaket. Två togglar; när ett paket är på visas dess byggsten-chips.*

| Funktion | Vad den gör | Me | UI | Ber | Plats | Not. |
|---|---|:--:|:--:|:--:|:--:|---|
| Toggle: UI | Slår på/av UI-paketet (UI-byggstenar + iPhone-ramar). | – | ⬜ | ⬜ | ⬜ |  |
| Toggle: Skillflöde | Slår på/av Skillflöde-paketet (noder för en Claude Code-skill). | – | ⬜ | ⬜ | ⬜ |  |
| UI → UI / Zon / Overlay | Lägger till rektangel märkt som UI-element / zon / overlay. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| UI → 15 Pro / 16 Pro | Lägger till en iPhone-skärmram att bygga UI ovanpå. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Skillflöde → Input / Output | Lägger till Input-/Output-nod (kapsel) i flödet. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Skillflöde → Skill | Lägger till en Skill-container som noderna ligger i. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Skillflöde → Subagent / Tool / MCP / Plugin | Lägger till respektive flödes-nod. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Skillflöde → MD-fil / Excel | Lägger till en nod som representerar en fil. | ⬜ | ⬜ | ⬜ | ⬜ |  |

---

## 6. Verktygsrad – Markera-flera-rad

*Var: Verktygsrad → Lägen-meny → Markera flera (raden visas då automatiskt).*

| Funktion | Vad den gör | Me | UI | Ber | Plats | Not. |
|---|---|:--:|:--:|:--:|:--:|---|
| Räknare "N markerade" | Visar hur många former som är markerade (ingen åtgärd). | – | ⬜ | ⬜ | ⬜ |  |
| Duplicera | Kopierar alla markerade former (kräver ≥1). | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Ta bort | Raderar alla markerade former (kräver ≥1). | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Centrera H | Justerar markerade former längs gemensam vågrät mittlinje (kräver ≥2). | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Centrera V | Justerar markerade former längs gemensam lodrät mittlinje (kräver ≥2). | ⬜ | ⬜ | ⬜ | ⬜ |  |

---

## 7. Verktygsrad – Lägen-meny

*Var: Verktygsrad → Lägen (reglage-ikonen).*

| Funktion | Vad den gör | Me | UI | Ber | Plats | Not. |
|---|---|:--:|:--:|:--:|:--:|---|
| Ny canvas (välj plattform) | Startar ny tom canvas; väljer plattform. | – | ⬜ | ⬜ | ⬜ |  |
| Mallar → AI-Skill | Lägger in färdig grupp: Skill-container med Input → Subagent → Output. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Mallar → UI-skärm | Lägger in en iPhone-skärmram att börja rita UI på. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Mallar → Arkitektur | Lägger in färdig grupp: modul kopplad till en dok.md-fil. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Aktuell plattform | Visar vilken plattform canvasen är låst till (inaktiv). | – | ⬜ | ⬜ | ⬜ |  |
| Visa regler för Godot | Visar Godot-reglerna (syns bara när plattform = Godot). | – | ⬜ | ⬜ | ⬜ |  |
| Spara / Spara… | Sparar canvasen (direkt om filen finns, annars spara-dialog). | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Spara som ny fil… | Sparar canvasen som en ny separat fil. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Öppna fil… | Öppnar en sparad canvas-fil. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Importera Mermaid… | Importerar Mermaid-kod (t.ex. från en AI) och ritar upp den. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Importera flera filer (jämför)… | Importerar flera filer, var och en i egen container, för jämförelse. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Visa Mermaid-kod | Visar canvasen som Mermaid-kod. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Kopiera Mermaid-kod | Kopierar hela koden till urklipp med ett tryck. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Exportera som bild → PNG (skarp) | Exporterar ytan som skarp PNG → delningsmeny. | – | ⬜ | ⬜ | ⬜ |  |
| Exportera som bild → JPG (mindre fil) | Exporterar ytan som mindre JPG → delningsmeny. | – | ⬜ | ⬜ | ⬜ |  |
| Mermaid vs app-funktioner | Facit-vyn: vad blir ren Mermaid vs appens egna funktioner. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Legend | Visar/döljer legend-panelen (skriv vad varje form/färg betyder). | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Markera flera | Slår på/av läget för att markera flera former (visar Markera-flera-raden). | – | ⬜ | ⬜ | ⬜ |  |
| Skärmläge → Porträtt / Landskap | Ställer appen i porträtt- eller landskapsläge. | – | ⬜ | ⬜ | ⬜ |  |
| Versionsrad | Visar milstolpe + versionsnummer (inaktiv). | – | ⬜ | ⬜ | ⬜ |  |

---

## 8. Canvas – Form-gester

*Var: direkt på en form på canvasen.*

| Funktion | Vad den gör | Me | UI | Ber | Plats | Not. |
|---|---|:--:|:--:|:--:|:--:|---|
| Enkeltryck | Markerar formen (visar handtag + markeringsram). | – | ⬜ | ⬜ | ⬜ |  |
| Dubbeltryck | Öppnar läs-/redigeringslappen intill formen (namn, prompt, anteckning). | – | ⬜ | ⬜ | ⬜ |  |
| Dubbeltryck på tabell | Öppnar tabell-redigeraren i stället för lappen. | – | ⬜ | ⬜ | ⬜ |  |
| Dra | Flyttar formen; nära kanten rullar tavlan med. | – | ⬜ | ⬜ | ⬜ |  |
| Dra container/telefon-ram | Flyttar containern och allt innehåll med. | – | ⬜ | ⬜ | ⬜ |  |
| Långtryck (~0,45 s) | Öppnar formens långtrycksmeny (kontextmeny). | – | ⬜ | ⬜ | ⬜ |  |
| Låst form → dra | Står still, kan inte flyttas/storleksändras (visar hänglås). | – | ⬜ | ⬜ | ⬜ |  |

---

## 9. Canvas – Anslutningsprickar (rita pil)

*Var: markerad form → de fyra gröna plus-prickarna (topp/höger/botten/vänster).*

| Funktion | Vad den gör | Me | UI | Ber | Plats | Not. |
|---|---|:--:|:--:|:--:|:--:|---|
| Skapa pil från en sida | Dra ut från en prick → pilen börjar på just den sidan; släpp på en form → pil skapas. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Gummiband-förhandsvisning | Streckad linje från form till finger medan du siktar. | – | ⬜ | ⬜ | ⬜ |  |
| Släpp i tomrum | Ingen pil skapas, gummibandet försvinner. | – | ⬜ | ⬜ | ⬜ |  |

---

## 10. Canvas – Pil-meny

*Var: pilens midpunkts-knapp → långtryck (meny). Dra i knappen = böj/skapa brytpunkt.*

| Funktion | Vad den gör | Me | UI | Ber | Plats | Not. |
|---|---|:--:|:--:|:--:|:--:|---|
| Dra midpunkt → waypoint | Skapar en brytpunkt så pilen böjer sig dit du drar. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Redigera text | Skriv etikett på pilen + välj ovanför/under linjen. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Riktning → Höger / Vänster / Båda / Ingen | Var pilspetsen sitter (framåt/bakåt/båda/ren linje). | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Stil → Hel / Streckad linje | Heldragen eller streckad linje. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Form på linjen → Rak | Rak linje mellan formerna. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Form på linjen → Böjd | Mjukt böjd linje som rundar runt former i vägen. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Form på linjen → Vinklad | Linje med rät vinkel (L-form/trappsteg). | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Färg → Standard/Röd/Blå/Grön/Orange/Lila/Gul/Grå | Sätter pilens färg. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Går ut från → Auto / Upp / Höger / Ner / Vänster | Vilken sida av startformen pilen lämnar. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Räta ut pil | Tar bort handdragen brytpunkt (visas bara om pilen har en). | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Ta bort pil | Raderar pilen. | ⬜ | ⬜ | ⬜ | ⬜ |  |

---

## 11. Canvas – Form-långtrycksmeny

*Var: form → långtryck → popover-meny. (Container-poster syns bara på containrar.)*

| Funktion | Vad den gör | Me | UI | Ber | Plats | Not. |
|---|---|:--:|:--:|:--:|:--:|---|
| Redigera | Öppnar formens fullständiga redigeringsruta (avancerat). | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Duplicera | Skapar en kopia av formen. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Lägg till / Visa anteckning | Öppnar formens anteckningsruta. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Lås fast / Lås upp | Låser formen så den inte kan flyttas/storleksändras (eller låser upp). | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Skapa underflöde / Hoppa in → | Öppnar formens inre flöde (Visio-drill); skapar tomt om inget finns. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Kopiera som skill (container) | Kopierar containern + innehåll som färdig mermaid-skill till urklipp. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Spara skill som fil (container) | Sparar containern som egen canvas-/skill-fil i iCloud. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Spara Mermaid inom container | Sparar bara formerna inuti containern som ren mermaid-fil. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Lager → Underst / Mellan / Överst | Z-ordning mot andra former. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Ta bort | Raderar formen (och dess pilar). | ⬜ | ⬜ | ⬜ | ⬜ |  |

---

## 12. Canvas – Läs-lapp (NoteCard)

*Var: form → dubbeltryck → lappen intill formen. (Eller via gul anteckningsbricka / indigo prompt-bricka.)*

| Funktion | Vad den gör | Me | UI | Ber | Plats | Not. |
|---|---|:--:|:--:|:--:|:--:|---|
| Redigera namn | Skriver formens namn direkt i lappen, sparas live. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Redigera anteckning | Skriver formens privata anteckning direkt i lappen, sparas live. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Prompt (visning) | Visar formens prompt skrivskyddat (markerbart, redigeras via reglage). | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Reglage-knapp | Öppnar avancerad redigering (textstil, prompt, listor m.m.). | – | ⬜ | ⬜ | ⬜ |  |
| Stäng-kryss | Stänger just den lappen (flera lappar kan vara öppna samtidigt). | – | ⬜ | ⬜ | ⬜ |  |
| Gul anteckningsbricka | Öppnar/stänger lappen för en form som har anteckning. | – | ⬜ | ⬜ | ⬜ |  |
| Indigo prompt-bricka | Öppnar/stänger lappen för en form som har prompt. | – | ⬜ | ⬜ | ⬜ |  |

---

## 13. Canvas – Brödsmulor (Visio-drill)

*Var: nere i ett underflöde (raden visas bara då).*

| Funktion | Vad den gör | Me | UI | Ber | Plats | Not. |
|---|---|:--:|:--:|:--:|:--:|---|
| Ut | Hoppar upp en nivå till föräldraflödet. | – | ⬜ | ⬜ | ⬜ |  |
| 🏠 Huvudflöde | Hoppar hela vägen till rotnivån. | – | ⬜ | ⬜ | ⬜ |  |
| Mellanliggande smula | Hoppar direkt till den nivån (nuvarande nivå ej tryckbar). | – | ⬜ | ⬜ | ⬜ |  |
| Centrering vid nivåbyte | Vyn centreras automatiskt på nya nivåns innehåll. | – | ⬜ | ⬜ | ⬜ |  |

---

## 14. Canvas – Handtag + markeringsläge

*Var: markerad form (handtag) / markeringsläge på (flermarkering).*

| Funktion | Vad den gör | Me | UI | Ber | Plats | Not. |
|---|---|:--:|:--:|:--:|:--:|---|
| Storlek proportionerligt (nere höger) | Ändrar bredd + höjd lika (bevarar proportion). Ej för container. | – | ⬜ | ⬜ | ⬜ |  |
| Storlek fritt (nere vänster) | Ändrar bredd och höjd var för sig. | – | ⬜ | ⬜ | ⬜ |  |
| Rotera (uppe vänster) | Roterar formen runt sitt centrum. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Ändpunkts-handtag (linje/pil-form) | Drar ut, kortar och vinklar en lös linje fritt. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Markeringsläge → tryck på form | Lägger till / tar bort form i flermarkeringen. | – | ⬜ | ⬜ | ⬜ |  |
| Markeringsläge → dra i tomrum | Markeringsruta (gummiband) markerar allt den överlappar. | – | ⬜ | ⬜ | ⬜ |  |
| Flytta hela markeringen | Drar du en markerad form flyttas alla markerade (låsta står still). | – | ⬜ | ⬜ | ⬜ |  |
| Skala hela markeringen (≥2) | Skalar alla markerade former runt gemensamt centrum. | – | ⬜ | ⬜ | ⬜ |  |

---

## 15. Canvas – Övrigt

*Var: på canvasen, utanför enskild form.*

| Funktion | Vad den gör | Me | UI | Ber | Plats | Not. |
|---|---|:--:|:--:|:--:|:--:|---|
| Tom yta → enkeltryck | Avmarkerar allt och avbryter pågående pil-läge. | – | ⬜ | ⬜ | ⬜ |  |
| Pil-läge → tryck form A, sedan B | Ritar pil genom att trycka (tap-to-connect). | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Länk-form → enkeltryck | Centrerar vyn på länkens partner på tavlan. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Centrera-knapp (sikte, nere höger) | Panorerar och centrerar vyn på allt ritat innehåll. | – | ⬜ | ⬜ | ⬜ |  |
| Expandera gren (grön plus-bricka) | Fäller ut en kollapsad gren igen. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Kollapsa gren (minus-bricka) | Döljer en gren från markerad nod. | ⬜ | ⬜ | ⬜ | ⬜ |  |

---

## 16. Sheets / dialoger

*Var: öppnas från menyer/gester ovan; egna fönster.*

| Funktion | Vad den gör | Me | UI | Ber | Plats | Not. |
|---|---|:--:|:--:|:--:|:--:|---|
| Redigera form (EditShapeSheet) | Avancerad: visa text, namn, textstil, justering, listor, skill-nr, prompt, anteckning, ta bort. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Anteckning (NoteMiniSheet) | Liten ruta för att bara läsa/skriva formens anteckning. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Mermaid-kod (MermaidCodeSheet) | Visar genererad kod live + Kopiera. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Anteckningar (NotePopupSheet) | Listar all text på canvasen (namn + anteckning per form). | – | ⬜ | ⬜ | ⬜ |  |
| Ny canvas (NewCanvasSheet) | Väljer plattform innan ny tom canvas. | – | ⬜ | ⬜ | ⬜ |  |
| Regler (PlatformRulesSheet) | Visar plattformens regel-/lexikontext. | – | ⬜ | ⬜ | ⬜ |  |
| Importera Mermaid (MermaidImportSheet) | Steg 1: kopiera AI-mall. Steg 2: klistra mermaid → importera till canvas. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Redigera tabell (TableEditorSheet) | Rubrik + celler + lägg till/ta bort rader/kolumner. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Hur funkar appen (MermaidVsAppSheet) | Facit: native Mermaid vs app-egna funktioner, färg = överlevnad, sök, kopiera AI-ramverk. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Legend-panel (LegendPanel) | Skriv vad varje form-kategori betyder; round-trippar som `%% legend …`. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Pil-text (EdgeLabelSheet) | Textfält för pil-text + placering (ovanför/under). | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Fil-dialoger (Öppna / Spara / Importera flera) | Systemets fil-väljare för öppna, spara och multi-import. | ⬜ | ⬜ | ⬜ | ⬜ |  |
| Komponentgalleri (ComponentGallery) | Intern verifiering (nås bara via launch-arg) — **ej användarfunktion**. | – | ⬜ | – | ⚠️ | Endast debug — ska den nås av Kim alls? |

---

## 17. Kvarstår / att bygga

*Inte en kontroll-lista — en överblick av vad som återstår, så genomgången har full kontext.*

### Gated på ditt "kör" (byggs inte på gissning)
| Punkt | Status |
|---|---|
| **Fas 2 – självbeskrivande export-legend** | Designad klar (6 agenter). Ändrar fil-formatet → väntar på ditt "kör fas 2". |
| **MC – n8n klar** | Pausat (din order). Återupptas på "ja". |
| **M4 – node contracts + `.skill.md`-export + dashboard** | Pausat. |

### Gated på din iPhone-verifiering (aktiv milstolpe MB "Grundappen sitter")
| Punkt | Status |
|---|---|
| Steg 1 – om-verifiera UX-111–122 mot v79 | Kräver se-appen + din iPhone. |
| Steg 2 – UX-111 "pan-stölden": större träffyta på pilhandtag | Klart när drag nära handtag inte panorerar bort allt. |
| Steg 3 – UX-112: klampa handtag till synlig yta | Så du når alla handtag. |
| Steg 4 – UX-113: pålitlig dubbeltapp → Redigera + ledtråd i tomt-läge | Din iPhone. |
| Steg 5 – UX-114: a11y-labels på allt interaktivt | Din iPhone. |

### Parkerade idéer (💡 Idébanken — byggs aldrig nu)
- 💡#3 "Kopiera som skill" får kontraktet inbäddat · 💡#4 Promptprotokoll fullt ut · 💡#5 Prompt-kompilator
  (appen genererar nod-prompten) · 💡#6 UI-prototyp-lager (Figma-lite) · 💡#7 Nästlad container-länk i **ren** Mermaid
  · 💡#11 Edge-routing-ombyggnad (resten).

### Små tekniska luckor (senare)
- Waypoints i fallback-parsern + stabila nod-ID (steg 6) · `PrivacyInfo.xcprivacy` inför App Store.

### Redan byggt men står kvar som idébanks-text (status-glapp att städa)
- Visio "hoppa in", multi-fil-import, UI-färgpalett, OSX-app (Mac Catalyst) — **byggda v90–v92**, men idébanken är inte avbockad.

---

*Skapad som genomgångsdokument. Bocka av yta för yta. Hittar du ⚠️ — skriv vad i Not.-kolumnen så fixar vi det.*
