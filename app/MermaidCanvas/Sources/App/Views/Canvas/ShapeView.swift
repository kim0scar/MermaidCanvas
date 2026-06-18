import SwiftUI
import UIKit

struct ShapeView: View {
    @Binding var shape: ShapeNode
    let edgeMode: Bool
    let markerMode: Bool
    let canvasScale: CGFloat
    let isPendingFrom: Bool
    let onEdgeTap: () -> Void
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    let onShowNote: () -> Void
    /// v63: snabbläsning av anteckning+prompt (read-only QuickReadSheet)
    let onQuickRead: () -> Void
    /// v41: öppnar tabell-redigeraren vid dubbelklick på tabell-form.
    var onTableEdit: ((UUID) -> Void)? = nil
    /// v39: rapporterar drag-position (canvas-koord) för auto-scroll. nil = drag avslutad.
    var onDragUpdate: ((CGPoint?) -> Void)? = nil
    /// v40: callback för att flytta ALLA markerade former (multi-select drag).
    var onMoveMultiSelection: ((CGSize) -> Void)? = nil
    /// v40: sann om denna form ingår i multiSelection
    var isInMultiSelection: Bool = false
    /// v44: rapporterar drag-delta för container — så inneliggande former kan flyttas med.
    var onContainerMove: ((CGSize) -> Void)? = nil
    /// v47: rapporterar att en form har slutat dras (efter position-uppdatering).
    /// CanvasModel använder detta för att (om)tilldela `childOfContainerId` baserat på
    /// var formen landade.
    var onDragEnded: ((UUID) -> Void)? = nil
    /// v66: kopiera container som skill-mermaid (bara containrar visar valet).
    var onCopySkill: ((UUID) -> Void)? = nil
    /// v70: spara container som egen skill-fil (bara containrar visar valet).
    var onSaveSkillFile: ((UUID) -> Void)? = nil

    @State private var dragOffset: CGSize = .zero
    @State private var lastMultiDragTranslation: CGSize? = nil
    @State private var lastContainerDragTranslation: CGSize = .zero
    /// v50.5 F4: egen popover-meny vid long-press — ersätter .contextMenu
    /// som triggade SwiftUI's snapshot-preview (svart blurred flash) innan
    /// menyn visades.
    @State private var showContextMenu: Bool = false

    private var pack: ColorPack { ColorPack.by(id: shape.colorPackId) }
    // v62: egna färger (fyllning + ram separat) går före paket/kategori.
    private var effectiveFill: Color {
        if let hex = shape.colorOverride, let c = Color(hexString: hex) { return c }
        return pack.fillColor
    }
    private var effectiveStroke: Color {
        if let hex = shape.strokeColorOverride, let c = Color(hexString: hex) { return c }
        return pack.id != "none" ? pack.strokeColor : shape.category.strokeColor
    }
    private var effectiveTextColor: Color {
        // Egen fyllning → välj svart/vit på luminans så texten alltid syns.
        if let hex = shape.colorOverride, Color(hexString: hex) != nil {
            return Color.isDarkHex(hex) ? .white : Color(hex: 0x111827)
        }
        return pack.textColor
    }

    /// v39: formatterat label med bullets/numrering + indrag.
    private var formattedLabel: String {
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

    private var textAlignment: TextAlignment {
        switch shape.textAlignment {
        case .leading:  return .leading
        case .trailing: return .trailing
        case .center:   return .center
        }
    }

    /// v74: container-rubrik — skill-containrar visar kedjenumret ("Skill 2 · namn").
    /// Steg 8: en skill-container inuti en annan container = "Subskill".
    private var containerHeaderTitle: String {
        let name = shape.label.isEmpty ? "Grupp" : formattedLabel
        guard shape.category == .skill else { return name }
        let kind = shape.childOfContainerId != nil ? "Subskill" : "Skill"
        if let nr = shape.skillNumber { return "\(kind) \(nr) · \(name)" }
        return kind == "Subskill" ? "Subskill · \(name)" : name
    }

    var body: some View {
        ZStack {
            ShapeRenderer(shape: shape, fill: effectiveFill, stroke: effectiveStroke,
                          containerTitle: containerHeaderTitle, isPendingFrom: isPendingFrom)
            // v36: lös linje/pil ritas via FreeLineView (background ger EmptyView)
            if shape.type == .line || shape.type == .arrow {
                FreeLineView(shape: shape, stroke: effectiveStroke)
            }
            // v50.3 R3: Containers label hanteras via separat .overlay nedan
            // (Lucidchart-stil ovanför ramen). Andra former behåller centrerad
            // text inuti ZStack:en.
            if shape.showLabel && shape.type != .container && shape.type != .phoneFrame {
                // v73: tom nod visar sin typ som svag platshållare (P4: "bara form+färg
                // skiljer Script från Bevis") — försvinner så fort Kim skriver eget namn.
                // Bara visning; exporten påverkas inte.
                Text(shape.label.isEmpty ? shape.category.displayName : formattedLabel)
                    .font(.system(size: shape.textStyle.fontSize * shape.sizeMultiplier,
                                  weight: shape.textStyle.fontWeight,
                                  design: .rounded))
                    .foregroundStyle(shape.label.isEmpty
                        ? effectiveTextColor.opacity(0.35)
                        : effectiveTextColor)
                    .multilineTextAlignment(textAlignment)
                    .lineLimit(6)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 8)
            }
        }
        .frame(width: ShapeGeometry.width(for: shape),
               height: ShapeGeometry.height(for: shape))
        .rotationEffect(.degrees(shape.rotation))
        .opacity(markerMode && !edgeMode ? 0.6 : 1.0)
        // v60: container-titeln bor nu i header-raden (se background) — ingen flytande tab.
        // v63: badge-tap → snabbläsning (read-only), inte redigering.
        // v66: badges ligger PÅ formen (ingen utstickande offset — Kims fynd:
        // "i vägen"); på container UNDER den 28pt höga headern så namnet syns.
        .overlay(alignment: .topTrailing) {
            if !shape.note.isEmpty && !markerMode {
                NoteBadge(canvasScale: canvasScale, onTap: onQuickRead)
                    .offset(x: -3, y: shape.type == .container ? 31 : 3)
                    .rotationEffect(.degrees(-shape.rotation))
            }
        }
        // v63: prompt-badge (indigo hjärna) i toppvänstra hörnet → snabbläsning.
        .overlay(alignment: .topLeading) {
            if !shape.prompt.isEmpty && shape.carriesPrompt && !markerMode {
                PromptBadge(canvasScale: canvasScale, onTap: onQuickRead)
                    .offset(x: 3, y: shape.type == .container ? 31 : 3)
                    .rotationEffect(.degrees(-shape.rotation))
            }
        }
        // v48 Fel #3+#4: CollapseBadge är flyttad från ShapeView till EdgesView
        // (renderas per utgående kant, vid kantens start). Se EdgeCollapseBadges.swift.
        .contentShape(Rectangle())
        // v73: formen som ETT a11y-element med begriplig svensk label —
        // för VoiceOver och för AI-agenter som läser a11y-trädet.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(shape.label.isEmpty
            ? shape.category.displayName
            : "\(shape.category.displayName): \(shape.label)")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("shape.\(shape.type.rawValue)")
        .position(
            x: shape.position.x + dragOffset.width,
            y: shape.position.y + dragOffset.height
        )
        // v46: enkel- och dubbeltap i exakt-ordning. SwiftUI fördröjer count:1 om
        // count:2 ligger SENARE i kedjan, så dubbelklick måste ligga FÖRE och
        // enkeltap kvar — annars triggas både select OCH edit vid dubbelklick.
        .onTapGesture(count: 2) {
            if shape.type == .table {
                onTableEdit?(shape.id)
            } else {
                onEdit()
            }
        }
        .onTapGesture(count: 1) {
            if markerMode {
                onSelect()
                return
            }
            if edgeMode {
                onEdgeTap()
            } else {
                onSelect()
            }
        }
        // v44: long-press borttaget — ConnectionHandle ersätter mekanismen.
        // v40: drag aktiverat i markerMode OM formen ingår i multiSelection.
        // Utan mask .none läggs inget gesture-recognizer på (undviker UIScrollView-kollision).
        .gesture(unifiedDragGesture, including: gestureActive ? .all : .none)
        // v50.5 F4: explicit long-press → popover (utan SwiftUI's contextMenu-
        // snapshot-flash). simultaneousGesture så drag-gesten fortfarande
        // fungerar. 0.45s = standard iOS long-press-känsla.
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45)
                .onEnded { _ in
                    // v50.5 (v5) M3: i edge-mode betyder håll-in inget — popa
                    // inte redigera-menyn då (användaren siktar på pil-ände).
                    guard !edgeMode else { return }
                    // v50.5 (v5) F13: haptic feedback (gamla .contextMenu gav
                    // system-haptic gratis — popover gör inte det).
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    showContextMenu = true
                }
        )
        .popover(isPresented: $showContextMenu) {
            ShapeContextMenu(
                noteIsEmpty: shape.note.isEmpty,
                onEdit:      { showContextMenu = false; onEdit() },
                onDuplicate: { showContextMenu = false; onDuplicate() },
                onShowNote:  { showContextMenu = false; onShowNote() },
                onDelete:    { showContextMenu = false; onDelete() },
                // v66: containrar kan kopieras som skill-mermaid
                onCopySkill: shape.type == .container && onCopySkill != nil
                    ? { showContextMenu = false; onCopySkill?(shape.id) }
                    : nil,
                onSaveSkillFile: shape.type == .container && onSaveSkillFile != nil
                    ? { showContextMenu = false; onSaveSkillFile?(shape.id) }
                    : nil
            )
            .presentationCompactAdaptation(.popover)
        }
    }

    /// Sann när drag-gesten ska vara aktiv: normalt läge, eller markeringsläge med multiSelection.
    private var gestureActive: Bool {
        !edgeMode && (!markerMode || isInMultiSelection)
    }

    /// v40: Enhetlig drag-gest — hanterar normal drag, multi-select drag och inaktivt läge.
    /// v44: rapporterar container-deltan live så inneliggande former följer med under drag.
    private var unifiedDragGesture: some Gesture {
        DragGesture(minimumDistance: isInMultiSelection ? 6 : 10,
                    coordinateSpace: .named("canvas"))
            .onChanged { v in
                if isInMultiSelection {
                    // Multi-select: flytta ALLA markerade former via delta
                    let prev = lastMultiDragTranslation ?? .zero
                    let delta = CGSize(
                        width: v.translation.width - prev.width,
                        height: v.translation.height - prev.height
                    )
                    lastMultiDragTranslation = v.translation
                    onMoveMultiSelection?(delta)
                    onDragUpdate?(v.location)
                } else if !markerMode {
                    // Normal drag: visa visuell offset
                    dragOffset = CGSize(
                        width: v.location.x - v.startLocation.x,
                        height: v.location.y - v.startLocation.y
                    )
                    // v44: container — flytta inneliggande former live med samma delta
                    if shape.type == .container {
                        let delta = CGSize(
                            width: dragOffset.width - lastContainerDragTranslation.width,
                            height: dragOffset.height - lastContainerDragTranslation.height
                        )
                        lastContainerDragTranslation = dragOffset
                        if delta.width != 0 || delta.height != 0 {
                            onContainerMove?(delta)
                        }
                    }
                    onDragUpdate?(v.location)
                }
                // markerMode utan multiSelection: ignorera drag (scrollview tar över)
            }
            .onEnded { v in
                if isInMultiSelection {
                    lastMultiDragTranslation = nil
                    onDragUpdate?(nil)
                } else if !markerMode {
                    shape.position.x += v.translation.width
                    shape.position.y += v.translation.height
                    dragOffset = .zero
                    lastContainerDragTranslation = .zero   // v44: reset för container-tracking
                    onDragUpdate?(nil)
                    // v47: efter position-uppdatering, om-tilldela container-förälder.
                    onDragEnded?(shape.id)
                }
            }
    }

    // background / stroke / highlight → Views/Canvas/ShapeRenderer.swift (MA spår A steg 5).
}
