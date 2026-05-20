import SwiftUI

/// v41: Redigeringsvy för tabellformer — öppnas med dubbelklick.
/// Visar en interaktiv tabell där man kan skriva i celler och lägga till rader/kolumner.
struct TableEditorSheet: View {
    let shapeId: UUID
    let initialRows: Int
    let initialCols: Int
    let initialCells: [[String]]
    let initialLabel: String
    let onSave: (_ label: String, _ rows: Int, _ cols: Int, _ cells: [[String]]) -> Void
    let onCancel: () -> Void

    @State private var label: String
    @State private var cells: [[String]]
    @FocusState private var focusedCell: CellId?

    struct CellId: Hashable {
        let row: Int
        let col: Int
    }

    init(shapeId: UUID,
         initialRows: Int,
         initialCols: Int,
         initialCells: [[String]],
         initialLabel: String,
         onSave: @escaping (_ label: String, _ rows: Int, _ cols: Int, _ cells: [[String]]) -> Void,
         onCancel: @escaping () -> Void) {
        self.shapeId = shapeId
        self.initialRows = initialRows
        self.initialCols = initialCols
        self.initialCells = initialCells
        self.initialLabel = initialLabel
        self.onSave = onSave
        self.onCancel = onCancel
        _label = State(initialValue: initialLabel)
        // Säkerställ rätt storlek på cells-matrisen
        var c = initialCells
        // Fyll ut till rätt antal rader
        while c.count < initialRows {
            c.append(Array(repeating: "", count: initialCols))
        }
        // Klipp av om för många rader
        if c.count > initialRows { c = Array(c.prefix(initialRows)) }
        // Säkerställ rätt antal kolumner per rad
        c = c.map { row in
            var r = row
            while r.count < initialCols { r.append("") }
            if r.count > initialCols { r = Array(r.prefix(initialCols)) }
            return r
        }
        _cells = State(initialValue: c)
    }

    var rows: Int { cells.count }
    var cols: Int { cells.first?.count ?? 0 }

    var body: some View {
        NavigationStack {
            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 0) {
                    // Rubriktextfält
                    TextField("Tabellrubrik", text: $label)
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

                    // Tabellgrid
                    VStack(spacing: 0) {
                        ForEach(0..<rows, id: \.self) { row in
                            HStack(spacing: 0) {
                                ForEach(0..<cols, id: \.self) { col in
                                    TextField("", text: Binding(
                                        get: { cells[row][col] },
                                        set: { cells[row][col] = $0 }
                                    ))
                                    .focused($focusedCell, equals: CellId(row: row, col: col))
                                    .font(.system(size: 15))
                                    .padding(8)
                                    .frame(minWidth: 80, idealWidth: 110, maxWidth: 160,
                                           minHeight: 40)
                                    .background(row == 0 ? Color(.systemGray5) : Color(.systemBackground))
                                    .overlay(
                                        Rectangle()
                                            .stroke(Color(.separator), lineWidth: 0.5)
                                    )
                                    .multilineTextAlignment(.center)
                                }
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separator), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                    // Knappar: lägg till rad / kolumn
                    HStack(spacing: 12) {
                        Button {
                            addRow()
                        } label: {
                            Label("Lägg till rad", systemImage: "plus.rectangle")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            addColumn()
                        } label: {
                            Label("Lägg till kolumn", systemImage: "rectangle.badge.plus")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        if rows > 1 {
                            Button {
                                removeLastRow()
                            } label: {
                                Image(systemName: "minus.rectangle")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.bordered)
                        }
                        if cols > 1 {
                            Button {
                                removeLastColumn()
                            } label: {
                                Image(systemName: "rectangle.badge.minus")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("Redigera tabell")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Klar") {
                        onSave(label, rows, cols, cells)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func addRow() {
        cells.append(Array(repeating: "", count: cols))
    }

    private func removeLastRow() {
        guard rows > 1 else { return }
        cells.removeLast()
    }

    private func addColumn() {
        cells = cells.map { $0 + [""] }
    }

    private func removeLastColumn() {
        guard cols > 1 else { return }
        cells = cells.map { Array($0.dropLast()) }
    }
}
