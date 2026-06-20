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
    /// V79-svep: spara formerna inom containern som ren mermaid-fil.
    var onSaveContainerMermaid: ((UUID) -> Void)? = nil
    /// V79-svep: lås/lås upp + sätt lager.
    var onToggleLock: ((UUID) -> Void)? = nil
    var onSetZLayer: ((UUID, Int) -> Void)? = nil
    /// Steg H: exportläge — rendera bara form + text (ingen badge-chrome) för bild-export.
    var exportMode: Bool = false

    @State private var dragOffset: CGSize = .zero
    @State private var lastMultiDragTranslation: CGSize? = nil
    @State private var lastContainerDragTranslation: CGSize = .zero
    /// v50.5 F4: egen popover-meny vid long-press — ersätter .contextMenu
    /// som triggade SwiftUI's snapshot-preview (svart blurred flash) innan
    /// menyn visades.
    @State private var showContextMenu: Bool = false

    // Härledda färg-/text-/rubrik-värden → ShapeView+Style.swift (R5-ratchet, steg H).

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
            if shape.type == .emoji {
                // v1.0: naken emoji — bara glyfen, stor, fyller formen (ingen ruta bakom).
                Text(shape.label.isEmpty ? "🙂" : shape.label)
                    .font(.system(size: ShapeGeometry.height(for: shape) * 0.78))
                    .minimumScaleFactor(0.2)
                    .lineLimit(1)
            } else if shape.showLabel && shape.type != .container && shape.type != .phoneFrame {
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
                    .padding(.horizontal, textHorizontalInset)
                    .offset(y: textVerticalOffset)
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
            if !shape.note.isEmpty && !markerMode && !exportMode {
                NoteBadge(canvasScale: canvasScale, onTap: onQuickRead)
                    .offset(x: -3, y: shape.type == .container ? 31 : 3)
                    .rotationEffect(.degrees(-shape.rotation))
            }
        }
        // v63: prompt-badge (indigo hjärna) i toppvänstra hörnet → snabbläsning.
        .overlay(alignment: .topLeading) {
            if !shape.prompt.isEmpty && shape.carriesPrompt && !markerMode && !exportMode {
                PromptBadge(canvasScale: canvasScale, onTap: onQuickRead)
                    .offset(x: 3, y: shape.type == .container ? 31 : 3)
                    .rotationEffect(.degrees(-shape.rotation))
            }
        }
        // Steg 9: phoneFrame visar modellnamnet UTANPÅ ramen (ovanför) — skärmytan
        // hålls fri. Syns även i bild-export (device-identitet, inte chrome).
        .overlay(alignment: .top) {
            if shape.type == .phoneFrame && shape.showLabel && !shape.label.isEmpty {
                Text(shape.label)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize()
                    .offset(y: -20)
                    .rotationEffect(.degrees(-shape.rotation))
            }
        }
        // V79-svep: hänglås-ikon på låst form (nere till höger, app-only chrome).
        .overlay(alignment: .bottomTrailing) {
            if shape.locked && !markerMode && !exportMode {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(4)
                    .background(Circle().fill(.ultraThinMaterial))
                    .offset(x: -3, y: -3)
                    .rotationEffect(.degrees(-shape.rotation))
                    .allowsHitTesting(false)
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
                    : nil,
                onSaveContainerMermaid: shape.type == .container && onSaveContainerMermaid != nil
                    ? { showContextMenu = false; onSaveContainerMermaid?(shape.id) }
                    : nil,
                locked: shape.locked,
                onToggleLock: { showContextMenu = false; onToggleLock?(shape.id) },
                zLayer: shape.zLayer,
                onSetZLayer: { z in onSetZLayer?(shape.id, z) }
            )
            .presentationCompactAdaptation(.popover)
        }
    }

    /// Sann när drag-gesten ska vara aktiv: normalt läge, eller markeringsläge med multiSelection.
    private var gestureActive: Bool {
        // V79-svep: låst form kan inte dras.
        !shape.locked && !edgeMode && (!markerMode || isInMultiSelection)
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
                    // v44: container/phoneFrame — flytta inneliggande former live (steg 9)
                    if shape.type.actsAsContainer {
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
