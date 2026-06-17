// Textstil-rad — utbruten ur ToolbarView (MA spår A steg 7–11). Beteende oförändrat.

import SwiftUI

extension ToolbarView {
    @ViewBuilder
    var textStylesSecondary: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // v40: En storlek-knapp → popup med R1/R2/R3/Aa
                let currentStyle = selectedShape?.textStyle ?? .body
                Button { showSizePicker = true } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "textformat.size")
                            .font(.system(size: 15, weight: .medium))
                        Text(stylePreview(currentStyle))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .confirmationDialog("Textstorlek", isPresented: $showSizePicker, titleVisibility: .visible) {
                    ForEach(TextStyle.allCases) { st in
                        Button(st.displayName) { applyTextStyle(st) }
                    }
                    Button("Avbryt", role: .cancel) {}
                }

                // v40: Fet-knapp (togglar mellan r1 och body)
                textActionButton(
                    icon: "bold",
                    label: "Fet",
                    active: selectedShape?.textStyle == .r1
                ) {
                    guard let id = model.selectedShapeId,
                          let idx = model.shapes.firstIndex(where: { $0.id == id }) else { return }
                    let current = model.shapes[idx].textStyle
                    model.shapes[idx].textStyle = current == .r1 ? .body : .r1
                }

                Divider().frame(height: 28).padding(.horizontal, 2)

                // Punktlista
                textActionButton(
                    icon: "list.bullet",
                    label: "Punkter",
                    active: selectedShape?.hasBullets == true && selectedShape?.hasNumberedList == false
                ) {
                    guard let id = model.selectedShapeId,
                          let idx = model.shapes.firstIndex(where: { $0.id == id }) else { return }
                    let on = !(model.shapes[idx].hasBullets)
                    model.shapes[idx].hasBullets = on
                    if on { model.shapes[idx].hasNumberedList = false }
                }

                // Numrerad lista
                textActionButton(
                    icon: "list.number",
                    label: "Numrerad",
                    active: selectedShape?.hasNumberedList == true
                ) {
                    guard let id = model.selectedShapeId,
                          let idx = model.shapes.firstIndex(where: { $0.id == id }) else { return }
                    let on = !(model.shapes[idx].hasNumberedList)
                    model.shapes[idx].hasNumberedList = on
                    if on { model.shapes[idx].hasBullets = false }
                }

                Divider().frame(height: 28).padding(.horizontal, 2)

                // v46: Textjustering L/C/R
                textActionButton(
                    icon: "text.alignleft",
                    label: "Vänster",
                    active: selectedShape?.textAlignment == .leading
                ) {
                    guard let id = model.selectedShapeId,
                          let idx = model.shapes.firstIndex(where: { $0.id == id }) else { return }
                    model.shapes[idx].textAlignment = .leading
                }
                textActionButton(
                    icon: "text.aligncenter",
                    label: "Centrera",
                    active: selectedShape?.textAlignment == .center
                ) {
                    guard let id = model.selectedShapeId,
                          let idx = model.shapes.firstIndex(where: { $0.id == id }) else { return }
                    model.shapes[idx].textAlignment = .center
                }
                textActionButton(
                    icon: "text.alignright",
                    label: "Höger",
                    active: selectedShape?.textAlignment == .trailing
                ) {
                    guard let id = model.selectedShapeId,
                          let idx = model.shapes.firstIndex(where: { $0.id == id }) else { return }
                    model.shapes[idx].textAlignment = .trailing
                }

                Divider().frame(height: 28).padding(.horizontal, 2)

                // Indrag vänster (minska)
                textActionButton(icon: "decrease.indent", label: "Indrag–", active: false) {
                    guard let id = model.selectedShapeId,
                          let idx = model.shapes.firstIndex(where: { $0.id == id }) else { return }
                    model.shapes[idx].indentLevel = max(0, model.shapes[idx].indentLevel - 1)
                }

                // Indrag höger (öka)
                textActionButton(icon: "increase.indent", label: "Indrag+", active: false) {
                    guard let id = model.selectedShapeId,
                          let idx = model.shapes.firstIndex(where: { $0.id == id }) else { return }
                    model.shapes[idx].indentLevel = min(3, model.shapes[idx].indentLevel + 1)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    var selectedShape: ShapeNode? {
        guard let id = model.selectedShapeId else { return nil }
        return model.shapes.first(where: { $0.id == id })
    }

    @ViewBuilder
    func textStyleChip(_ st: TextStyle) -> some View {
        let isCurrent: Bool = {
            guard let id = model.selectedShapeId,
                  let s = model.shapes.first(where: { $0.id == id }) else { return false }
            return s.textStyle == st
        }()
        Button {
            applyTextStyle(st)
        } label: {
            Text(stylePreview(st))
                .font(.system(size: st.fontSize, weight: st.fontWeight, design: .rounded))
                .foregroundStyle(isCurrent ? Color.white : Color.primary)
                .frame(minWidth: 40)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(isCurrent ? Color.accentColor : Color(.systemBackground)))
                .overlay(Capsule().stroke(Color.primary.opacity(0.1), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func textActionButton(icon: String,
                          label: String,
                          active: Bool,
                          action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(active ? Color.white : Color.primary)
                .frame(width: 38, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(active ? Color.accentColor : Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }

    func stylePreview(_ st: TextStyle) -> String {
        switch st {
        case .r1:   return "R1"
        case .r2:   return "R2"
        case .r3:   return "R3"
        case .body: return "Aa"
        }
    }

    func applyTextStyle(_ st: TextStyle) {
        guard let id = model.selectedShapeId,
              let idx = model.shapes.firstIndex(where: { $0.id == id }) else { return }
        model.shapes[idx].textStyle = st
    }
}
