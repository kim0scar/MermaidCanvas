import SwiftUI

/// Arkitektur-läget renderas som en filträd-look:
/// folder → bold header med chevron
/// file → indented row med doc-ikon
/// module / service / data → kort-staplar grupperade
/// Heuristik: filer som ligger inom 200pt från en mapp-form anses tillhöra den.
struct ArchitectureRenderer: View {
    let shapes: [ShapeNode]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                folderTree
                if !nodes(.module).isEmpty || !nodes(.service).isEmpty || !nodes(.data).isEmpty {
                    Divider()
                    moduleCards
                }
                if !nodes(.note).isEmpty {
                    Divider()
                    notesList
                }
            }
            .padding(20)
        }
        .background(Color.appGroupedBackground)
    }

    private func nodes(_ cat: ShapeCategory) -> [ShapeNode] {
        shapes.filter { $0.category == cat }
    }

    @ViewBuilder
    private var folderTree: some View {
        let folders = nodes(.folder).sorted { $0.position.y < $1.position.y }
        let allFiles = nodes(.file)
        if !folders.isEmpty || !allFiles.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("📁 Struktur").font(.title3.bold()).padding(.bottom, 4)
                ForEach(folders) { folder in
                    folderRow(folder, files: allFiles.filter { near(folder, $0) })
                }
                let orphanFiles = allFiles.filter { f in !folders.contains(where: { near($0, f) }) }
                ForEach(orphanFiles) { file in fileRow(file, indent: 0) }
            }
        }
    }

    @ViewBuilder
    private func folderRow(_ folder: ShapeNode, files: [ShapeNode]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "folder.fill").foregroundStyle(.yellow)
                Text(folder.label).font(.body.weight(.semibold))
            }
            ForEach(files.sorted { $0.position.y < $1.position.y }) { file in
                fileRow(file, indent: 1)
            }
        }
    }

    @ViewBuilder
    private func fileRow(_ file: ShapeNode, indent: Int) -> some View {
        HStack {
            Image(systemName: "doc.text").foregroundStyle(.secondary)
            Text(file.label).font(.callout)
        }
        .padding(.leading, CGFloat(indent) * 22)
    }

    @ViewBuilder
    private var moduleCards: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🧩 Moduler & tjänster").font(.title3.bold())
            ForEach(shapes.filter { [.module, .service, .data].contains($0.category) }) { node in
                HStack {
                    Image(systemName: iconFor(node.category))
                        .foregroundStyle(node.category.fillColor)
                    VStack(alignment: .leading) {
                        Text(node.label).font(.body.weight(.medium))
                        Text(node.category.displayName.uppercased())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(10)
                .background(Color.appSecondaryGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    @ViewBuilder
    private var notesList: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("📝 Anteckningar").font(.title3.bold())
            ForEach(nodes(.note)) { n in
                Label(n.label, systemImage: "note.text").font(.callout)
            }
        }
    }

    private func near(_ folder: ShapeNode, _ file: ShapeNode) -> Bool {
        let dx = abs(folder.position.x - file.position.x)
        let dy = abs(folder.position.y - file.position.y)
        return dx < 200 && dy < 200
    }

    private func iconFor(_ cat: ShapeCategory) -> String {
        switch cat {
        case .module:  return "cube"
        case .service: return "server.rack"
        case .data:    return "cylinder.fill"
        case .folder:  return "folder.fill"
        case .file:    return "doc"
        default:       return "questionmark"
        }
    }
}
