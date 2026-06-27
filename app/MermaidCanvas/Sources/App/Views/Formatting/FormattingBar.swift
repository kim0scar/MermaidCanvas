import SwiftUI

/// 1.3 S1.3: EN formateringsmeny — delad komponent. Renderas i TVÅ lägen med exakt
/// samma knappar (kan aldrig glida isär): (1) verktygsfältets textstil-rad när en form
/// är markerad, (2) ovanför tangentbordet när text redigeras direkt i formen (Apple
/// Notes-mönstret). Ren presentation — värden in, åtgärder ut via closures; varje host
/// sköter sin egen undo-snapshot.
/// 1.4: kompakt — listor och justering fälls till EN ikon var (popup). `showListsAndIndent`
/// döljer listor+indrag i keyboard-läget (de syns inte live i det råa textfältet — bara
/// storlek + justering renderas live; listor/indrag visas när formen är MARKERAD).
struct FormattingBar: View {
    let style: TextStyle
    let alignment: TextAlignMode
    let hasBullets: Bool
    let hasNumbered: Bool
    var showListsAndIndent: Bool = true
    var onStyle: (TextStyle) -> Void
    var onToggleBullets: () -> Void
    var onToggleNumbered: () -> Void
    var onAlign: (TextAlignMode) -> Void
    /// delta: +1 ökar indrag, -1 minskar (host klampar 0…3).
    var onIndent: (Int) -> Void

    @State private var showSizePicker = false
    @State private var showAlignPicker = false
    @State private var showListsPicker = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // Storlek/rubrik — popup med R1/R2/R3/Aa.
                Button { showSizePicker = true } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "textformat.size")
                            .font(.system(size: 15, weight: .medium))
                        Text(stylePreview(style))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .accessibilityIdentifier("toolbar.textSize")
                .accessibilityLabel("Textstorlek")
                .confirmationDialog("Textstorlek", isPresented: $showSizePicker, titleVisibility: .visible) {
                    ForEach(TextStyle.allCases) { st in
                        Button(st.displayName) { onStyle(st) }
                    }
                    Button("Avbryt", role: .cancel) {}
                }

                Divider().frame(height: 28).padding(.horizontal, 2)

                // Justering — EN ikon (visar aktuell), popup L/C/R. Renderas live i fältet.
                Button { showAlignPicker = true } label: { chipLabel(alignIcon(alignment), active: false) }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("toolbar.align")
                    .accessibilityLabel("Justering")
                    .confirmationDialog("Justering", isPresented: $showAlignPicker, titleVisibility: .visible) {
                        Button("Vänster") { onAlign(.leading) }
                        Button("Centrera") { onAlign(.center) }
                        Button("Höger") { onAlign(.trailing) }
                        Button("Avbryt", role: .cancel) {}
                    }

                if showListsAndIndent {
                    Divider().frame(height: 28).padding(.horizontal, 2)

                    // Lista — EN ikon, popup. (Döljs medan man skriver — syns ej live i råtext.)
                    Button { showListsPicker = true } label: {
                        chipLabel(hasNumbered ? "list.number" : "list.bullet", active: hasBullets || hasNumbered)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("toolbar.list")
                    .accessibilityLabel("Lista")
                    .confirmationDialog("Lista", isPresented: $showListsPicker, titleVisibility: .visible) {
                        Button("Punkter") { if !hasBullets { onToggleBullets() } }
                        Button("Numrerad") { if !hasNumbered { onToggleNumbered() } }
                        Button("Ingen") {
                            if hasBullets { onToggleBullets() }
                            if hasNumbered { onToggleNumbered() }
                        }
                        Button("Avbryt", role: .cancel) {}
                    }

                    Divider().frame(height: 28).padding(.horizontal, 2)

                    button(icon: "decrease.indent", label: "Indrag–", active: false) { onIndent(-1) }
                    button(icon: "increase.indent", label: "Indrag+", active: false) { onIndent(1) }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    @ViewBuilder
    private func chipLabel(_ icon: String, active: Bool) -> some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(active ? Color.white : Color.primary)
            .frame(width: 38, height: 36)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(active ? Color.accentColor : Color.appChipBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
    }

    @ViewBuilder
    private func button(icon: String, label: String, active: Bool,
                        action: @escaping () -> Void) -> some View {
        Button(action: action) { chipLabel(icon, active: active) }
            .buttonStyle(.plain)
            .accessibilityLabel(label)
    }

    private func alignIcon(_ a: TextAlignMode) -> String {
        switch a {
        case .leading:  return "text.alignleft"
        case .center:   return "text.aligncenter"
        case .trailing: return "text.alignright"
        }
    }

    private func stylePreview(_ st: TextStyle) -> String {
        switch st {
        case .r1:   return "R1"
        case .r2:   return "R2"
        case .r3:   return "R3"
        case .body: return "Aa"
        }
    }
}
