import XCTest
import CoreGraphics
@testable import MermaidCanvas

/// v65: Regressionstest med EXAKTA innehållet i webbskrap-flode.md —
/// kedjan med ROUTER-vägval (kod / browser-MCP / LLM). Låser: router-grenar
/// med etiketter, 3 grenar in i samma memory-nod, containrar + barn, prompts på alla noder.
final class V65SkrapFlodeTests: XCTestCase {

    private let skrapFil = ##"""
---
title: Webbskrap-kedjan
spec_type: flow
---

# Webbskrap-kedjan — skrapa en webbsida med rätt verktyg

Kedjan analyserar FÖRST hur sidan är byggd tekniskt, väljer SEDAN verktyg:
kod (statisk HTML), browser-MCP (JS-renderad) eller LLM-läsning (annars).
Kontrakt: `SKILL-KEDJA-KONTRAKT.md` i MermaidCanvas-repot.
Säg **"skrapa <URL>"** till Claude Code så körs hela kedjan.

```mermaid
flowchart TD
    input_trigger["Skrapa webbsida"]:::input
    %% input_trigger pos: 400,120
    %% input_trigger prompt: Trigger: Kim skriver 'skrapa <URL>' (+ ev. vad han vill ha ut, t.ex. 'skrapa example.com – alla priser'). INPUT till kedjan: URL:en och målet. Saknas mål → målet är 'sidans huvudinnehåll som strukturerad markdown'.
    %% input_trigger note: Starta med: skrapa https://... och vad du vill få ut.

    subgraph skill_sidanalys ["sidanalys"]
        tool_hamta["Hämta sidan rå"]:::tool
        agent_klassa["Identifiera teknisk uppbyggnad"]:::agent
    end
    %% skill_sidanalys container-pos: 400,330
    %% skill_sidanalys prompt: Skill 1: tar reda på HUR sidan är byggd så rätt verktyg kan väljas. Två steg i ordning: hämta rå, sedan klassificera.
    %% tool_hamta pos: 290,350
    %% tool_hamta prompt: INPUT: URL:en från triggern. UPPGIFT: hämta sidan RÅ utan rendering: kör curl -sL med vanlig browser-User-Agent, spara HTTP-status, content-type och hela HTML-svaret. Hämta även robots.txt (respektera Disallow för sökvägen — om skrapning är förbjuden: stoppa kedjan enligt felregeln). OUTPUT: rå HTML + headers vidare till nästa steg i samma skill (ingen fil ännu).
    %% tool_hamta note: Rå hämtning = utan JavaScript. Det är skillnaden som avslöjar sidtypen.
    %% agent_klassa pos: 510,350
    %% agent_klassa prompt: INPUT: rå HTML + headers från förra steget. UPPGIFT: klassificera sidan i EXAKT en av tre typer med belägg: (1) STATISK HTML = innehållet Kim vill ha syns redan i rå HTML (sök efter måltexten/datat i källkoden). (2) JS-RENDERAD = tom root-div (t.ex. <div id="root">), stora JS-bundles, innehållet SAKNAS i rå HTML. (3) OKLART/SKYDDAT = login-vägg, captcha, cloudflare-block, eller svårtolkat. Leta också efter öppet API: fetch/XHR-URL:er i källkoden eller <link rel=alternate type=application/json> — notera fynd som genväg. OUTPUT: skriv webbskrap/steg1-analys.md — H1 'Sidanalys <URL>', raderna 'Typ: statisk html|js-renderad|oklart', 'Belägg: <1-2 meningar>', 'API-genväg: <URL eller ingen>', 'Mål: <vad Kim vill ha ut>'.
    %% agent_klassa note: Belägget måste stå i filen — nästa steg litar blint på typraden.

    memory_steg1["steg1-analys.md"]:::memory
    %% memory_steg1 pos: 400,540
    %% memory_steg1 prompt: Överlämningsfil 1. Sökväg: webbskrap/steg1-analys.md (relativt canvas-filens mapp i iCloud). Format: H1 + raderna Typ/Belägg/API-genväg/Mål. Routern läser BARA denna fil.
    %% memory_steg1 note: Typ-raden styr vägvalet i routern under.

    router_verktyg{"Vilket verktyg?"}:::router
    %% router_verktyg pos: 400,700
    %% router_verktyg prompt: Läs raden 'Typ:' i webbskrap/steg1-analys.md. statisk html → grenen 'statisk html' (kod). js-renderad → grenen 'js-renderad' (browser-MCP). Allt annat (oklart/skyddat) → grenen utan etikett (LLM). Finns API-genväg → den får användas i VALD gren som snabbare väg till samma data.
    %% router_verktyg note: Tre vägar: kod är billigast, browser klarar JS, LLM är reserven som alltid funkar.

    subgraph skill_skrapa_kod ["skrapa-kod"]
        tool_kod["Skrapa med kod"]:::tool
    end
    %% skill_skrapa_kod container-pos: 130,890
    %% skill_skrapa_kod prompt: Skill 2a: statisk sida → hämta och parsa med program-kod. Snabbast och billigast.
    %% tool_kod pos: 130,910
    %% tool_kod prompt: INPUT: webbskrap/steg1-analys.md (URL, mål, ev. API-genväg). UPPGIFT: skriv och kör ett litet python-skript (eller curl + jq om API-genväg finns): hämta sidan, parsa HTML:en och extrahera målet (rubriker, tabeller, priser — det Mål-raden säger). Ingen browser, ingen LLM-tolkning av rådata. OUTPUT: skriv webbskrap/steg2-data.md — H1 'Skrapad data', raderna 'Källa: <URL>', 'Verktyg: kod', 'Hämtat: <datum>' och därunder datat som markdown-tabell eller punktlista.
    %% tool_kod note: Väljs när innehållet redan finns i rå HTML.

    subgraph skill_skrapa_browser ["skrapa-browser"]
        tool_browser["Skrapa med browser-MCP"]:::tool
    end
    %% skill_skrapa_browser container-pos: 400,890
    %% skill_skrapa_browser prompt: Skill 2b: JS-renderad sida → riktig browser via Playwright-MCP som kör sidans JavaScript.
    %% tool_browser pos: 400,910
    %% tool_browser prompt: INPUT: webbskrap/steg1-analys.md (URL, mål). UPPGIFT: använd playwright-headless-MCP: browser_navigate till URL:en, vänta tills innehållet laddats (browser_wait_for på text som hör till målet), ta browser_snapshot och extrahera målet ur snapshotet; vid behov browser_evaluate för att läsa ut data ur DOM:en. OUTPUT: skriv webbskrap/steg2-data.md — samma format som skrapa-kod men 'Verktyg: browser-mcp'.
    %% tool_browser note: Väljs när rå HTML är tom och innehållet byggs av JavaScript.

    subgraph skill_skrapa_llm ["skrapa-llm"]
        agent_llm["LLM läser sidan"]:::agent
    end
    %% skill_skrapa_llm container-pos: 670,890
    %% skill_skrapa_llm prompt: Skill 2c: reserven — LLM-läsning när sidtypen är oklar eller delvis skyddad.
    %% agent_llm pos: 670,910
    %% agent_llm prompt: INPUT: webbskrap/steg1-analys.md (URL, mål, belägg). UPPGIFT: hämta sidan med WebFetch och låt LLM:en läsa och plocka ut målet ur texten. Kommer du inte åt innehållet (login/captcha): STOPPA enligt felregeln — skriv '## FEL' i output-filen med vad som blockerar och vad Kim kan göra (t.ex. logga in själv och klistra in HTML). Gissa ALDRIG fram data. OUTPUT: skriv webbskrap/steg2-data.md — samma format, 'Verktyg: llm'.
    %% agent_llm note: Reserven. Får aldrig hitta på data — hellre FEL-rubrik än gissning.

    memory_steg2["steg2-data.md"]:::memory
    %% memory_steg2 pos: 400,1100
    %% memory_steg2 prompt: Överlämningsfil 2. Sökväg: webbskrap/steg2-data.md. Format: H1 'Skrapad data' + raderna Källa/Verktyg/Hämtat + datat som tabell/punktlista. EXAKT en av grenarna skriver den. Nästa skill läser BARA denna fil.
    %% memory_steg2 note: Alla tre grenarna landar här — samma format oavsett verktyg.

    subgraph skill_leverans ["leverans"]
        agent_strukturera["Strukturera resultatet"]:::agent
    end
    %% skill_leverans container-pos: 400,1290
    %% skill_leverans prompt: Skill 3: gör skrapdatat till Kims färdiga resultat.
    %% agent_strukturera pos: 400,1310
    %% agent_strukturera prompt: INPUT: webbskrap/steg2-data.md (läs filen, inget annat). UPPGIFT: städa och strukturera datat mot målet: ta bort dubbletter, sortera logiskt, sätt korta rubriker (Kim har dyslexi: korta ord, viktigast först). Lägg överst raden 'Källa: <URL> — hämtad <datum> med <verktyg>'. OUTPUT: skriv webbskrap/resultat.md med H1 'Resultat: <målet>' + det strukturerade innehållet.

    output_svar["Visa resultatet i chatten"]:::output
    %% output_svar pos: 400,1500
    %% output_svar prompt: Slutsteg: visa webbskrap/resultat.md ordagrant i chatten + en rad om var alla filer ligger. Kedjan är klar.

    input_trigger --> tool_hamta
    tool_hamta --> agent_klassa
    agent_klassa -->|"skriver"| memory_steg1
    memory_steg1 -->|"läser"| router_verktyg
    router_verktyg -->|"statisk html"| tool_kod
    router_verktyg -->|"js-renderad"| tool_browser
    router_verktyg --> agent_llm
    tool_kod -->|"skriver"| memory_steg2
    tool_browser -->|"skriver"| memory_steg2
    agent_llm -->|"skriver"| memory_steg2
    memory_steg2 -->|"läser"| agent_strukturera
    agent_strukturera --> output_svar

    classDef input fill:#ffffff,stroke:#15803d,color:#111827;
    classDef tool fill:#ffffff,stroke:#c2410c,color:#111827;
    classDef agent fill:#ffffff,stroke:#4338ca,color:#111827;
    classDef memory fill:#ffffff,stroke:#6d28d9,color:#111827;
    classDef router fill:#ffffff,stroke:#0e7490,color:#111827;
    classDef output fill:#ffffff,stroke:#b91c1c,color:#111827;
```

Vill du ändra kedjan? Flytta noder, byt prompts i appen — appen sparar dina
ändringar som en KOPIA med nytt namn (originalet rörs aldrig). Säg sedan
"kör flödet webbskrap" eller "bygg skills av flödet webbskrap".
"""##

    private var parsed: MermaidParser.ParsedCanvas { MermaidParser.parse(skrapFil) }

    func testAllaNoderOchContainrar() {
        let p = parsed
        XCTAssertEqual(p.shapes.count, 16, "11 noder + 5 containrar (skills)")
        XCTAssertEqual(p.edges.count, 12)
        let containers = p.shapes.filter { $0.type == .container }
        XCTAssertEqual(containers.count, 5, "5 skills: sidanalys, kod, browser, llm, leverans")
    }

    func testKategorier() {
        let p = parsed
        func cat(_ label: String) -> ShapeCategory? {
            p.shapes.first { $0.label == label }?.category
        }
        XCTAssertEqual(cat("Skrapa webbsida"), .input)
        XCTAssertEqual(cat("Hämta sidan rå"), .tool)
        XCTAssertEqual(cat("Identifiera teknisk uppbyggnad"), .agent)
        XCTAssertEqual(cat("steg1-analys.md"), .memory)
        XCTAssertEqual(cat("Vilket verktyg?"), .router)
        XCTAssertEqual(cat("steg2-data.md"), .memory)
        XCTAssertEqual(cat("Visa resultatet i chatten"), .output)
    }

    func testRouternHarTreGrenarMedRattEtiketter() {
        let p = parsed
        guard let router = p.shapes.first(where: { $0.label == "Vilket verktyg?" }) else {
            return XCTFail("Routern saknas")
        }
        XCTAssertEqual(router.type, .diamond, "Routern ritas som diamant")
        let grenar = p.edges.filter { $0.from == router.id }
        XCTAssertEqual(grenar.count, 3, "Tre vägval: kod, browser, LLM")
        XCTAssertEqual(Set(grenar.map { $0.label }), ["statisk html", "js-renderad", ""],
                       "Två etiketterade grenar + en default (utan etikett)")
    }

    func testAllaTreGrenarLandarISammaMemoryNod() {
        let p = parsed
        guard let steg2 = p.shapes.first(where: { $0.label == "steg2-data.md" }) else {
            return XCTFail("steg2-data.md saknas")
        }
        let inkommande = p.edges.filter { $0.to == steg2.id }
        XCTAssertEqual(inkommande.count, 3, "kod + browser + llm skriver alla hit")
    }

    func testContainrarHarSinaBarn() {
        let p = parsed
        func shape(_ label: String) -> ShapeNode? { p.shapes.first { $0.label == label } }
        guard let sidanalys = shape("sidanalys"),
              let hamta = shape("Hämta sidan rå"),
              let klassa = shape("Identifiera teknisk uppbyggnad") else {
            return XCTFail("Noder saknas")
        }
        XCTAssertEqual(hamta.childOfContainerId, sidanalys.id)
        XCTAssertEqual(klassa.childOfContainerId, sidanalys.id)
    }

    func testAllaNoderHarPromptOchUtvaldaHarAnteckning() {
        let p = parsed
        // Alla utom output-/input-fria undantag: i den här kedjan har ALLA noder prompt
        let utanPrompt = p.shapes.filter { $0.prompt.isEmpty }
        XCTAssertTrue(utanPrompt.isEmpty,
                      "Alla noder + containrar ska ha prompt: \(utanPrompt.map { $0.label })")
        // Anteckningar (note) finns på utvalda noder → läs-ikonerna syns i appen
        let medNote = p.shapes.filter { !$0.note.isEmpty }
        XCTAssertGreaterThanOrEqual(medNote.count, 5, "Minst 5 noder har anteckning")
    }
}
