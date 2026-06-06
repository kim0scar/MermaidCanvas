import XCTest
import CoreGraphics
@testable import MermaidCanvas

/// v61.2: Regressionstest med EXAKTA innehållet i morgonkoll-flode.md —
/// referens-kedjan för skill-kedjor (SKILL-KEDJA-KONTRAKT.md).
/// Låser: parsning av containrar + barn-medlemskap (childOfContainerId i fallback),
/// kategorier, positioner och kant-etiketter.
final class V61KedjeFilTests: XCTestCase {

    private let kedjeFil = ##"""
---
title: Morgonkoll-kedjan
spec_type: flow
---

# Morgonkoll-kedjan — referens för skill-kedjor

Tre skills som avlöser varandra. Varje violett nod = en markdown-fil som lämnas
över mellan skillsen. Kontrakt: `SKILL-KEDJA-KONTRAKT.md` i MermaidCanvas-repot.
Säg **"kör flödet morgonkoll"** till Claude Code så körs hela kedjan.

```mermaid
flowchart TD
    input_trigger["Kör morgonkoll"]:::input
    %% input_trigger pos: 200,120
    %% input_trigger prompt: Trigger: Kim skriver 'kör morgonkoll' (eller schemaläggs senare via /schedule). Ingen input behövs.

    subgraph skill_mejlsvep ["mejl-svep"]
        tool_gmail["Hämta olästa mejl"]:::tool
    end
    %% skill_mejlsvep container-pos: 200,330
    %% skill_mejlsvep prompt: Skill 1: hämtar Kims olästa mejl och sparar en rå översikt som fil.
    %% tool_gmail pos: 200,350
    %% tool_gmail prompt: INPUT: ingen (trigger startar). UPPGIFT: Sök i Kims Gmail via MCP-verktyget search_threads med query 'is:unread newer_than:1d', max 20 trådar. För varje tråd: avsändare, ämne, kärnan i 1 mening (läs tråden med get_thread om ämnet är otydligt). OUTPUT: skriv markdown till överlämningsfilen steg1-mejl.md — H1 'Mejl-svep <dagens datum>', raden 'Antal: <N>', sedan tabell med kolumnerna Avsändare, Ämne, Kärna. Inga andra kommentarer i filen.

    memory_steg1["steg1-mejl.md"]:::memory
    %% memory_steg1 pos: 200,540
    %% memory_steg1 prompt: Överlämningsfil 1. Sökväg: morgonkoll/steg1-mejl.md (relativt canvas-filens mapp i iCloud). Format: H1 + 'Antal: N' + tabell Avsändare-Ämne-Kärna. Nästa skill läser BARA denna fil.

    subgraph skill_sammanfatta ["sammanfatta"]
        agent_prioritera["Prioritera i 3 hinkar"]:::agent
    end
    %% skill_sammanfatta container-pos: 200,730
    %% skill_sammanfatta prompt: Skill 2: läser mejlöversikten och sorterar i viktigt/kan vänta/brus.
    %% agent_prioritera pos: 200,750
    %% agent_prioritera prompt: INPUT: morgonkoll/steg1-mejl.md (läs filen, inget annat). UPPGIFT: sortera varje mejl i exakt en av tre hinkar: VIKTIGT = kräver handling av Kim idag (pengar, deadlines, personer som väntar på svar), KAN VÄNTA = ska hanteras men inte idag, BRUS = nyhetsbrev/notiser/reklam. Motivera varje VIKTIGT med en mening. OUTPUT: skriv morgonkoll/steg2-sammanfattning.md — överst raden 'Viktiga: <N>', sedan H2 'VIKTIGT' med punktlista (avsändare — ämne — varför), H2 'KAN VÄNTA' med punktlista, H2 'BRUS' med bara antalet.

    memory_steg2["steg2-sammanfattning.md"]:::memory
    %% memory_steg2 pos: 200,940
    %% memory_steg2 prompt: Överlämningsfil 2. Sökväg: morgonkoll/steg2-sammanfattning.md. Format: 'Viktiga: N' + H2 VIKTIGT/KAN VÄNTA/BRUS. Nästa skill läser BARA denna fil.

    subgraph skill_rapport ["rapport"]
        agent_rapport["Skriv Kims rapport"]:::agent
    end
    %% skill_rapport container-pos: 200,1130
    %% skill_rapport prompt: Skill 3: gör sammanfattningen till Kims korta morgonrapport.
    %% agent_rapport pos: 200,1150
    %% agent_rapport prompt: INPUT: morgonkoll/steg2-sammanfattning.md (läs filen, inget annat). UPPGIFT: skriv Kims morgonrapport — max 5 punkter, kortast möjliga meningar (Kim har dyslexi: korta ord, viktigast först). Prefix per punkt: 🔴 för VIKTIGT-poster (en punkt per post), 🟡 en samlad punkt för KAN VÄNTA (antal + tema), ⚪ en punkt för BRUS (bara antal). OUTPUT: skriv morgonkoll/morgonrapport.md med H1 'Morgonrapport <datum>' + punkterna.

    output_svar["Visa rapporten i chatten"]:::output
    %% output_svar pos: 200,1340
    %% output_svar prompt: Slutsteg: visa morgonrapport.md ordagrant i chatten + en rad om var alla tre filerna ligger. Kedjan är klar.

    input_trigger --> tool_gmail
    tool_gmail -->|"skriver"| memory_steg1
    memory_steg1 -->|"läser"| agent_prioritera
    agent_prioritera -->|"skriver"| memory_steg2
    memory_steg2 -->|"läser"| agent_rapport
    agent_rapport --> output_svar

    classDef input fill:#ffffff,stroke:#15803d,color:#111827;
    classDef tool fill:#ffffff,stroke:#c2410c,color:#111827;
    classDef agent fill:#ffffff,stroke:#4338ca,color:#111827;
    classDef memory fill:#ffffff,stroke:#6d28d9,color:#111827;
    classDef output fill:#ffffff,stroke:#b91c1c,color:#111827;
```

Vill du ändra kedjan? Flytta noder, byt prompts i appen, spara — säg sedan
"kör flödet morgonkoll" igen. Filen är kontraktet.
"""##

    func testKedjeFilenParsasKomplett() {
        let parsed = MermaidParser.parse(kedjeFil)

        // 3 containrar + 7 noder, 6 kanter — inga fantomnoder
        XCTAssertEqual(parsed.shapes.count, 10)
        XCTAssertEqual(parsed.edges.count, 6)
        XCTAssertEqual(parsed.shapes.filter { $0.type == .container }.count, 3)
        XCTAssertEqual(parsed.specType, .flow)

        // Kategorier
        XCTAssertEqual(parsed.shapes.filter { $0.category == .memory }.count, 2)
        XCTAssertEqual(parsed.shapes.filter { $0.category == .agent }.count, 2)
        XCTAssertEqual(parsed.shapes.filter { $0.category == .tool }.count, 1)

        // v61.2: subgraph-medlemskap → childOfContainerId (annars routas pilarna
        // runt containern som hinder)
        let mejlsvep = parsed.shapes.first { $0.type == .container && $0.label == "mejl-svep" }
        let toolNode = parsed.shapes.first { $0.category == .tool }
        XCTAssertNotNil(mejlsvep)
        XCTAssertEqual(toolNode?.childOfContainerId, mejlsvep?.id,
                       "tool_gmail ska vara barn till mejl-svep-containern")
        let rapport = parsed.shapes.first { $0.type == .container && $0.label == "rapport" }
        let rapportAgent = parsed.shapes.first { $0.label == "Skriv Kims rapport" }
        XCTAssertEqual(rapportAgent?.childOfContainerId, rapport?.id)

        // Memory-noder = överlämnings-filer, med prompts (sökväg + format)
        let steg1 = parsed.shapes.first { $0.label == "steg1-mejl.md" }
        XCTAssertTrue(steg1?.prompt.contains("morgonkoll/steg1-mejl.md") == true)

        // Kant-etiketter
        XCTAssertEqual(parsed.edges.filter { $0.label == "skriver" }.count, 2)
        XCTAssertEqual(parsed.edges.filter { $0.label == "läser" }.count, 2)

        // Allt på x=200 (handpositionerat) — inget får hamna på auto-layout
        for s in parsed.shapes {
            XCTAssertEqual(s.position.x, 200, accuracy: 1, "\(s.label) ska ligga på x=200")
        }
    }
}
