import XCTest
@testable import MermaidCanvas

/// v61: regressionstest med EXAKTA innehållet i v61-demo-från-claude.md
/// (filen Kim öppnar som första test av Claude→Kim-riktningen).
final class V61DemoFileTests: XCTestCase {

    private let demoContent = """
    ---
    title: v61-demo — Claude ritade detta
    spec_type: flow
    ---

    # v61-demo — Claude ritade detta

    Rå mermaid, INGEN state-JSON. Öppna i appen (v61): du ska se ett riktigt
    flödesschema uppifrån-och-ned — inte en cirkel av former.

    ```mermaid
    flowchart TD
        input_N0["Morgonkoll 07:00"]:::input --> agent_N1["Sammanfatta mejl"]:::agent
        agent_N1 --> router_N2{"Något viktigt?"}:::router
        router_N2 -->|"ja"| output_N3["Mejla Kim"]:::output
        router_N2 --> output_N4["Logga tyst"]:::output
        %% input_N0 prompt: varje morgon 07:00
        %% agent_N1 prompt: Sammanfatta olästa mejl i 3 punkter

        classDef input fill:#ffffff,stroke:#15803d,color:#111827;
        classDef agent fill:#ffffff,stroke:#4338ca,color:#111827;
        classDef router fill:#ffffff,stroke:#a16207,color:#111827;
        classDef output fill:#ffffff,stroke:#b91c1c,color:#111827;
    ```

    Funkar det? Då är tvåvägs-språket komplett: du ritar → jag bygger,
    jag ritar → du ser.
    """

    func testDemoFilenParsasTillFemFormerOchFyraKanter() {
        let parsed = MermaidParser.parse(demoContent)

        XCTAssertEqual(parsed.shapes.count, 5, "5 noder: input, agent, router, 2×output")
        XCTAssertEqual(parsed.edges.count, 4, "4 kanter")
        XCTAssertEqual(parsed.specType, .flow)
        XCTAssertEqual(parsed.title, "v61-demo — Claude ritade detta")

        // Kategorier från :::suffix
        XCTAssertEqual(parsed.shapes.filter { $0.category == .output }.count, 2)
        XCTAssertEqual(parsed.shapes.first?.category, .input)

        // Router är diamant
        XCTAssertEqual(parsed.shapes.first { $0.category == .router }?.type, .diamond)

        // Prompt-metadata
        let input = parsed.shapes.first { $0.category == .input }
        XCTAssertEqual(input?.prompt, "varje morgon 07:00")

        // Kant-etiketten "ja"
        XCTAssertTrue(parsed.edges.contains { $0.label == "ja" }, "Router-grenen 'ja' ska finnas")

        // TD-layout: input överst, agent under, router under agent
        let agent = parsed.shapes.first { $0.category == .agent }
        let router = parsed.shapes.first { $0.category == .router }
        XCTAssertLessThan(input!.position.y, agent!.position.y, "TD: input ovanför agent")
        XCTAssertLessThan(agent!.position.y, router!.position.y, "TD: agent ovanför router")

        // Inga fantomnoder från classDef-raderna
        XCTAssertFalse(parsed.shapes.contains { $0.label.contains("fill") },
                       "classDef får inte bli noder")
    }
}
