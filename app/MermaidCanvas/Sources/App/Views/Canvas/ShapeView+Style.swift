import SwiftUI

/// Härledda presentations-värden för ShapeView (utbrutna ur ShapeView.swift för
/// R5-ratchet, steg H): färg (fyllning/ram/text), formaterat label, text-inset
/// och container-rubrik. Rena funktioner av `shape` — ingen state.
extension ShapeView {
    var pack: ColorPack { ColorPack.by(id: shape.colorPackId) }

    // v62: egna färger (fyllning + ram separat) går före paket/kategori.
    var effectiveFill: Color {
        if let hex = shape.colorOverride, let c = Color(hexString: hex) { return c }
        return pack.fillColor
    }
    var effectiveStroke: Color {
        if let hex = shape.strokeColorOverride, let c = Color(hexString: hex) { return c }
        return pack.id != "none" ? pack.strokeColor : shape.category.strokeColor
    }
    var effectiveTextColor: Color {
        // Egen fyllning → välj svart/vit på luminans så texten alltid syns.
        if let hex = shape.colorOverride, Color(hexString: hex) != nil {
            return Color.isDarkHex(hex) ? .white : Color(hex: 0x111827)
        }
        return pack.textColor
    }

    /// v39: formatterat label med bullets/numrering + indrag.
    var formattedLabel: String {
        let indent = String(repeating: "  ", count: max(0, shape.indentLevel))
        let lines = shape.label.split(separator: "\n", omittingEmptySubsequences: false)
        if shape.hasNumberedList {
            return lines.enumerated()
                .map { "\(indent)\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
        } else if shape.hasBullets {
            return lines.map { "\(indent)• \($0)" }.joined(separator: "\n")
        } else if shape.indentLevel > 0 {
            return lines.map { "\(indent)\($0)" }.joined(separator: "\n")
        }
        return shape.label
    }

    var textAlignment: TextAlignment {
        switch shape.textAlignment {
        case .leading:  return .leading
        case .trailing: return .trailing
        case .center:   return .center
        }
    }

    /// G2a: extra sido-marginal för former som smalnar av — texten centreras i
    /// bounding-boxen, så utan inset spiller den över triangelns/rombens sneda kanter.
    var textHorizontalInset: CGFloat {
        switch shape.type {
        case .triangle: return 18   // bara nedre mitten är bred nog
        case .diamond:  return 22   // romben smalnar mot vänster/höger spets
        // 1.4 (Kims fynd): cirkeln smalnar runt hela kanten → texten spillde över kurvan.
        // Proportionell marginal ger ~70 % textbredd (inskriven box) oavsett storlek.
        case .circle:   return max(10, ShapeGeometry.width(for: shape) * 0.15)
        default:        return 8
        }
    }

    /// G2a: triangeln är bred bara nedtill → skjut texten nedåt mot basen.
    var textVerticalOffset: CGFloat {
        switch shape.type {
        case .triangle: return ShapeGeometry.height(for: shape) * 0.20
        default:        return 0
        }
    }

    /// 1.3: long-press-menyns innehåll (utbrutet ur body för R5-plats).
    @ViewBuilder var contextMenuContent: some View {
        ShapeContextMenu(
            noteIsEmpty: shape.note.isEmpty,
            onEdit:      { showContextMenu = false; onEdit() },
            onDuplicate: { showContextMenu = false; onDuplicate() },
            onShowNote:  { showContextMenu = false; onShowNote() },
            onDelete:    { showContextMenu = false; onDelete() },
            onCopySkill: shape.type == .container && onCopySkill != nil
                ? { showContextMenu = false; onCopySkill?(shape.id) } : nil,
            onSaveSkillFile: shape.type == .container && onSaveSkillFile != nil
                ? { showContextMenu = false; onSaveSkillFile?(shape.id) } : nil,
            onSaveContainerMermaid: shape.type == .container && onSaveContainerMermaid != nil
                ? { showContextMenu = false; onSaveContainerMermaid?(shape.id) } : nil,
            locked: shape.locked,
            onToggleLock: { showContextMenu = false; onToggleLock?(shape.id) },
            zLayer: shape.zLayer,
            onSetZLayer: { z in onSetZLayer?(shape.id, z) },
            hasSubCanvas: shape.subCanvas != nil,
            onEnterSubprocess: { showContextMenu = false; onEnterSubprocess?(shape.id) }
        )
        .presentationCompactAdaptation(.popover)
    }

    /// 1.5: fet-toggle gör texten en notch tyngre än rubriknivåns egen vikt (fet på
    /// brödtext → fet; fet på en redan fet rubrik → ännu tyngre). Syns alltid.
    var effectiveWeight: Font.Weight {
        guard shape.bold else { return shape.textStyle.fontWeight }
        switch shape.textStyle.fontWeight {
        case .regular, .medium, .semibold: return .bold
        default:                           return .heavy
        }
    }
    var labelFont: Font {
        .system(size: shape.textStyle.fontSize * shape.sizeMultiplier,
                weight: effectiveWeight, design: .rounded)
    }

    #if os(iOS)
    /// Bug 3: samma typsnitt som `labelFont`, men som UIFont åt LiveTextEditor (UITextView).
    var labelUIFont: UIFont {
        let size = shape.textStyle.fontSize * shape.sizeMultiplier
        var f = UIFont.systemFont(ofSize: size, weight: uiWeight(effectiveWeight))
        if let d = f.fontDescriptor.withDesign(.rounded) { f = UIFont(descriptor: d, size: size) }
        if shape.italic,
           let d = f.fontDescriptor.withSymbolicTraits(f.fontDescriptor.symbolicTraits.union(.traitItalic)) {
            f = UIFont(descriptor: d, size: size)
        }
        return f
    }

    private func uiWeight(_ w: Font.Weight) -> UIFont.Weight {
        switch w {
        case .ultraLight: return .ultraLight
        case .thin:       return .thin
        case .light:      return .light
        case .medium:     return .medium
        case .semibold:   return .semibold
        case .bold:       return .bold
        case .heavy:      return .heavy
        case .black:      return .black
        default:          return .regular
        }
    }

    var nsTextAlignment: NSTextAlignment {
        switch shape.textAlignment {
        case .leading:  return .left
        case .center:   return .center
        case .trailing: return .right
        }
    }

    /// Bug 3: FormattingBar i LiveTextEditor:s inputAccessoryView — SAMMA meny som tidigare
    /// (storlek·justering·lista·indrag·B/I/U·Klar), samma callbacks. Färg bor i topp-paletten (1.5.5).
    @ViewBuilder var editingFormattingBar: some View {
        FormattingBar(
            style: shape.textStyle,
            alignment: shape.textAlignment,
            hasBullets: shape.hasBullets,
            hasNumbered: shape.hasNumberedList,
            showListsAndIndent: true,
            onStyle: { st in onBeginTextEdit?(shape.id); shape.textStyle = st },
            onToggleBullets: { onBeginTextEdit?(shape.id)
                let on = !shape.hasBullets; shape.hasBullets = on
                if on { shape.hasNumberedList = false } },
            onToggleNumbered: { onBeginTextEdit?(shape.id)
                let on = !shape.hasNumberedList; shape.hasNumberedList = on
                if on { shape.hasBullets = false } },
            onAlign: { a in onBeginTextEdit?(shape.id); shape.textAlignment = a },
            onIndent: { d in onBeginTextEdit?(shape.id)
                shape.indentLevel = min(3, max(0, shape.indentLevel + d)) },
            onDone: { isEditing = false },
            bold: shape.bold, italic: shape.italic, underline: shape.underline,
            onToggleBold: { onBeginTextEdit?(shape.id); shape.bold.toggle() },
            onToggleItalic: { onBeginTextEdit?(shape.id); shape.italic.toggle() },
            onToggleUnderline: { onBeginTextEdit?(shape.id); shape.underline.toggle() }
        )
    }
    #endif


    /// 1.3 (S1.1): form-text-innehållet — emoji-glyf, inline-redigering, platshållare
    /// eller formaterat label. Utbrutet ur ShapeView.body för R5-plats (ShapeView var 299/300)
    /// och så redigerings-grenen kan växa i Fas 2 (per-rad-stil) utan att spränga taket.
    @ViewBuilder var labelContent: some View {
        if shape.type == .emoji {
            // v1.0: naken emoji — bara glyfen, stor, fyller formen (ingen ruta bakom).
            Text(shape.label.isEmpty ? "🙂" : shape.label)
                .font(.system(size: ShapeGeometry.height(for: shape) * 0.78))
                .minimumScaleFactor(0.2)
                .lineLimit(1)
        } else if shape.showLabel && shape.type != .container && shape.type != .phoneFrame {
            if isEditing && !exportMode {
                // 1.3 → Bug 3 (Kim): skriv direkt I formen. På iOS en UITextView som RITAR
                // punkt/nummer/indrag LIVE i marginalen (LiveTextEditor) medan texten hålls ren.
                // FormattingBar bor i inputAccessoryView (keyboard-toolbar visas ej för UITextView).
                #if os(iOS)
                LiveTextEditor(
                    text: $shape.label,
                    isEditing: $isEditing,
                    font: labelUIFont,
                    textColor: UIColor(effectiveTextColor),
                    alignment: nsTextAlignment,
                    underline: shape.underline,
                    listKind: shape.hasNumberedList ? .numbered : (shape.hasBullets ? .bullet : .none),
                    indentLevel: shape.indentLevel,
                    onEndEdit: { onEndTextEdit?() },
                    accessory: { AnyView(editingFormattingBar) }
                )
                .frame(maxWidth: .infinity)
                .padding(.horizontal, max(0, textHorizontalInset - 4))
                #else
                // macOS: SwiftUI-fält (live-bullets är iOS-först, Kims ordning — flaggat).
                TextField("", text: $shape.label, axis: .vertical)
                    .focused($labelFocused)
                    .textFieldStyle(.plain)
                    .font(labelFont)
                    .italic(shape.italic)
                    .underline(shape.underline)
                    .foregroundStyle(effectiveTextColor)
                    .multilineTextAlignment(textAlignment)
                    .lineLimit(1...6)
                    .padding(.horizontal, textHorizontalInset)
                    .onChange(of: labelFocused) { _, focused in if !focused { isEditing = false; onEndTextEdit?() } }
                #endif
            } else if shape.label.isEmpty {
                // 1.3 (Kim): tom form — svag "dubbeltryck för text"-ledtråd BARA när markerad.
                if isSelected && !exportMode {
                    Text("dubbeltryck\nför text")
                        .font(.system(size: shape.textStyle.fontSize * shape.sizeMultiplier * 0.72, design: .rounded))
                        .foregroundStyle(effectiveTextColor.opacity(0.3))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, textHorizontalInset)
                }
            } else {
                Text(formattedLabel)
                    .font(labelFont)
                    .italic(shape.italic)
                    .underline(shape.underline)
                    .foregroundStyle(effectiveTextColor)
                    .multilineTextAlignment(textAlignment)
                    .lineLimit(6)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, textHorizontalInset)
                    .offset(y: textVerticalOffset)
            }
        }
    }

    /// v74: container-rubrik — skill-containrar visar kedjenumret ("Skill 2 · namn").
    /// Steg 8: en skill-container inuti en annan container = "Subskill".
    var containerHeaderTitle: String {
        let name = shape.label.isEmpty ? "Grupp" : formattedLabel
        guard shape.category == .skill else { return name }
        let kind = shape.childOfContainerId != nil ? "Subskill" : "Skill"
        if let nr = shape.skillNumber { return "\(kind) \(nr) · \(name)" }
        return kind == "Subskill" ? "Subskill · \(name)" : name
    }
}
