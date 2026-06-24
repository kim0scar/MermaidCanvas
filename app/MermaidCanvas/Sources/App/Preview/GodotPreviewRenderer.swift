import SwiftUI

/// Godot-läget renderas som en scene-träd-vy (Godot scene-panel-känsla).
/// Visar former grupperade per Godot-nodtyp så Kim kan se en mental modell
/// av .tscn-scenen innan export.
struct GodotPreviewRenderer: View {
    let shapes: [ShapeNode]
    let edges: [EdgeConnection]

    private let nodeOrder: [ShapeCategory] = [
        .godot_scene, .godot_control, .godot_container,
        .godot_panel, .godot_button, .godot_label,
        .godot_signal, .godot_script
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("🎮 Godot scene-träd").font(.title3.bold())
                Text("Förhandsvisning innan export till .tscn / .gd")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(nodeOrder, id: \.self) { cat in
                    let list = shapes.filter { $0.category == cat }
                    if !list.isEmpty {
                        sectionHeader(cat)
                        ForEach(list) { shape in
                            nodeRow(shape: shape, cat: cat)
                        }
                    }
                }

                if !signals.isEmpty {
                    Divider().padding(.vertical, 8)
                    Text("⚡ Signaler").font(.headline)
                    ForEach(signals) { s in
                        Label(s.label.isEmpty ? "signal" : s.label, systemImage: "bolt.fill")
                            .font(.callout)
                    }
                }

                if !notes.isEmpty {
                    Divider().padding(.vertical, 8)
                    Text("📝 Anteckningar").font(.headline)
                    ForEach(notes) { n in
                        Label(n.label, systemImage: "note.text").font(.callout)
                    }
                }
            }
            .padding(20)
        }
        .background(Color.appGroupedBackground)
    }

    private var signals: [ShapeNode] {
        shapes.filter { $0.category == .godot_signal }
    }

    private var notes: [ShapeNode] {
        shapes.filter { $0.category == .note }
    }

    @ViewBuilder
    private func sectionHeader(_ cat: ShapeCategory) -> some View {
        HStack(spacing: 8) {
            Image(systemName: iconFor(cat))
                .font(.callout)
                .foregroundStyle(cat.fillColor)
            Text(cat.displayName.uppercased())
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func nodeRow(shape: ShapeNode, cat: ShapeCategory) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconFor(cat))
                .font(.body)
                .foregroundStyle(cat.fillColor)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(shape.label.isEmpty ? cat.emptyLabelHint : shape.label)
                    .font(.body.weight(.medium))
                Text(godotNodeType(cat))
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                if !shape.note.isEmpty {
                    Text(shape.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(10)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func iconFor(_ cat: ShapeCategory) -> String {
        switch cat {
        case .godot_scene:     return "rectangle.stack"
        case .godot_control:   return "square.dashed"
        case .godot_container: return "rectangle.3.group"
        case .godot_panel:     return "rectangle"
        case .godot_button:    return "button.horizontal"
        case .godot_label:     return "textformat"
        case .godot_signal:    return "bolt"
        case .godot_script:    return "curlybraces"
        default:               return "circle"
        }
    }

    private func godotNodeType(_ cat: ShapeCategory) -> String {
        switch cat {
        case .godot_scene:     return "Scene (.tscn)"
        case .godot_control:   return "Control"
        case .godot_container: return "VBox/HBox/MarginContainer"
        case .godot_panel:     return "Panel / PanelContainer"
        case .godot_button:    return "Button"
        case .godot_label:     return "Label"
        case .godot_signal:    return "signal"
        case .godot_script:    return "GDScript (.gd)"
        default:               return ""
        }
    }
}
