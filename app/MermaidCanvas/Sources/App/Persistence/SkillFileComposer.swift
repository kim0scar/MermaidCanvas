import Foundation
import CoreGraphics

/// v74: Bygger den PORTABLA skill-filen vid "Spara skill som fil".
/// Filen ska fungera på vilken Claude Code som helst, utan skills och utan projekt:
/// frontmatter (skill_name/skill_nr) + inbäddat exekverings-kontrakt + mermaid +
/// state-JSON. Kontraktet ligger FÖRE mermaid-blocket — reglerna ska vara lästa
/// innan flödet. Parsern påverkas inte: den tar första mermaid-staketet och
/// kontraktet innehåller aldrig kodstaket (frysregel i SkillExportContract).
enum SkillFileComposer {

    static func compose(skillName: String,
                        skillNumber: Int?,
                        shapes: [ShapeNode],
                        edges: [EdgeConnection],
                        canvasSize: CGSize,
                        platform: Platform,
                        activeShapePacks: Set<ShapePack>,
                        legend: [String: String]) -> String {
        let mermaid = MermaidGenerator.generate(
            shapes: shapes, edges: edges, canvasSize: canvasSize,
            specType: .flow, legend: legend)
        let state = MermaidGenerator.canvasStateJSON(
            shapes: shapes, edges: edges, canvasSize: canvasSize,
            specType: .flow, platform: platform,
            activeShapePacks: activeShapePacks,
            collapsedEdgeIds: [], legend: legend)
        let today = String(ISO8601DateFormatter().string(from: Date()).prefix(10))
        let packsList = ShapePack.allCases
            .filter { activeShapePacks.contains($0) }
            .map { $0.rawValue }
            .joined(separator: ",")
        let safeName = skillName.replacingOccurrences(of: "\n", with: " ")
        let nrLine = skillNumber.map { "skill_nr: \($0)\n" } ?? ""
        let heading = skillNumber.map { "Skill \($0) · \(safeName)" } ?? safeName

        return """
        ---
        title: \(safeName)
        skill_name: \(safeName)
        \(nrLine)spec_type: flow
        platform: \(platform.rawValue)
        shape_packs: \(packsList)
        contract_version: \(SkillExportContract.version)
        exported_by: Visuali2e \(AppVersion.current)
        last_updated: \(today)
        ---

        # \(heading)

        ## Exekverings-kontrakt (läs FÖRST — gäller hela flödet nedan)

        \(SkillExportContract.text)

        ## Flödet

        ```mermaid
        \(mermaid)
        ```

        <!-- mermaidcanvas-state
        \(state)
        -->
        """
    }
}
