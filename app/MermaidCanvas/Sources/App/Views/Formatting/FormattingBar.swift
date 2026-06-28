import SwiftUI

/// EN formateringsmeny — delad komponent, renderas i TVÅ lägen med samma knappar
/// (kan aldrig glida isär): (1) verktygsfältets textstil-rad när en form är markerad,
/// (2) ovanför tangentbordet när text redigeras direkt i formen (Apple Notes).
/// 1.5 (Kim): INGEN scroll — få ikoner, var och en poppar en undermeny uppåt (som de
/// andra menyerna). `showListsAndIndent` döljer listor+indrag i skriv-läget (de syns ej
/// live i råtextfältet → bor i markerad-form-raden). `onDone` ger en "Klar"-knapp som
/// stänger tangentbordet (sätts bara i skriv-läget; sekundärraden stängs med svajp-grabbern).
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
    var onDone: (() -> Void)? = nil
    // 1.5: fet/kursiv/understruken — toggles i storleks-galleriet.
    var bold: Bool = false
    var italic: Bool = false
    var underline: Bool = false
    var onToggleBold: () -> Void = {}
    var onToggleItalic: () -> Void = {}
    var onToggleUnderline: () -> Void = {}

    @State private var showSizePicker = false
    @State private var showAlignPicker = false
    @State private var showListsPicker = false
    @State private var showIndentPicker = false

    var body: some View {
        HStack(spacing: 6) {
            // 1.5-fix (Kim): i skriv-läget (onDone satt) centreras kontrollerna så raden inte
            // känns tom (2 små knappar längst till vänster + stort tomrum + Klar långt bort).
            if onDone != nil { Spacer(minLength: 8) }
            // Storlek/rubrik — popup (Del B byter till visuellt galleri).
            Button { showSizePicker = true } label: {
                // 1.5-fix (Kim): EN storlek-glyf (visar aktuell nivå). Ikonen "textformat.size"
                // såg ut som "Aa" intill textens "Aa" → dubbelt. Behåll nivå-texten.
                Text(stylePreview(style))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .frame(minWidth: 24)
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .accessibilityIdentifier("toolbar.textSize")
            .accessibilityLabel("Textstorlek")
            .popover(isPresented: $showSizePicker) {
                TextSizeGallery(current: style, bold: bold, italic: italic, underline: underline,
                                onPick: { onStyle($0); showSizePicker = false },
                                onToggleBold: onToggleBold, onToggleItalic: onToggleItalic,
                                onToggleUnderline: onToggleUnderline)
                    .presentationCompactAdaptation(.popover)
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

                // Lista — EN ikon, popup.
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

                // Indrag — EN ikon, popup (Öka/Minska) — som de andra menyerna.
                Button { showIndentPicker = true } label: { chipLabel("increase.indent", active: false) }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("toolbar.indent")
                    .accessibilityLabel("Indrag")
                    .confirmationDialog("Indrag", isPresented: $showIndentPicker, titleVisibility: .visible) {
                        Button("Öka indrag") { onIndent(1) }
                        Button("Minska indrag") { onIndent(-1) }
                        Button("Avbryt", role: .cancel) {}
                    }
            }

            if let onDone {
                Spacer(minLength: 8)
                Button("Klar", action: onDone)
                    .font(.system(size: 15, weight: .semibold))
                    .accessibilityIdentifier("toolbar.done")
            }
        }
        .padding(.horizontal, 2)
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

    private func alignIcon(_ a: TextAlignMode) -> String {
        switch a {
        case .leading:  return "text.alignleft"
        case .center:   return "text.aligncenter"
        case .trailing: return "text.alignright"
        }
    }

    private func stylePreview(_ st: TextStyle) -> String {
        switch st {
        case .jatte: return "XL"
        case .r1:    return "R1"
        case .r2:    return "R2"
        case .r3:    return "R3"
        case .body:  return "Aa"
        }
    }
}
