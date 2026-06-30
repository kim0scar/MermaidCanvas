// Chips — utbruten ur ToolbarView (MA spår A steg 7–11). Beteende oförändrat.

import SwiftUI

extension ToolbarView {
    /// v66: flödes-chip — formen i KATEGORINS färg + etikett under.
    /// (skillFlowChips + docChip utbrutna till ToolbarView+SkillFlowChips.swift, 1.5.4 R5.)
    @ViewBuilder
    func flowChip(_ type: ShapeType, _ category: ShapeCategory,
                  _ label: String, accId: String) -> some View {
        Button {
            model.addShape(type, at: canvasCenter, category: category)
        } label: {
            VStack(spacing: 2) {
                ZStack {
                    switch type {
                    case .diamond:
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(category.strokeColor, lineWidth: 2)
                            .frame(width: 15, height: 15)
                            .rotationEffect(.degrees(45))
                    case .pill:
                        Capsule()
                            .stroke(category.strokeColor, lineWidth: 2)
                            .frame(width: 24, height: 15)
                    case .octagon:
                        OctagonShape()
                            .stroke(category.strokeColor, lineWidth: 2)
                            .frame(width: 18, height: 18)
                    case .cylinder:
                        CylinderShape()
                            .stroke(category.strokeColor, lineWidth: 2)
                            .frame(width: 20, height: 18)
                    default:
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(category.strokeColor, lineWidth: 2)
                            .frame(width: 24, height: 16)
                    }
                }
                .frame(width: 36, height: 24)
                .background(Circle().fill(.ultraThinMaterial).frame(width: 34, height: 34))
                Text(label)
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundStyle(category.strokeColor)
                    .lineLimit(1)
            }
            .frame(width: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accId)
        .accessibilityLabel("Lägg till \(label)-nod")
    }

    /// v51.1: enhetlig geometri-chip. Storlek via `iconSize` (canvas-proportion) +
    /// rätt SwiftUI-form per typ. Gör chip-raderna kompakta och trivialt omordningsbara.
    @ViewBuilder
    func geoChip(_ type: ShapeType, accId: String, frame: CGFloat = 44, onTap: @escaping () -> Void) -> some View {
        shapeChipGeneric(type: type, accId: accId, onTap: onTap) {
            let s = DesignTokens.Chip.iconSize(for: type)
            ZStack { geoChipShape(type, size: s) }
                .frame(width: frame, height: frame)
                .background(Circle().fill(.ultraThinMaterial))
                .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
                // v60: behåll ≥44pt tap-yta även om frame krymps till 40 (8-på-rad).
                .contentShape(Circle().inset(by: min(0, (frame - 44) / 2)))
        }
    }

    @ViewBuilder
    func geoChipShape(_ type: ShapeType, size s: CGSize) -> some View {
        let stroke = DesignTokens.Shape.chipStrokeWidth
        switch type {
        case .circle:
            Circle().stroke(Color.primary, lineWidth: stroke).frame(width: s.height, height: s.height)
        case .pill:
            Capsule(style: .continuous).stroke(Color.primary, lineWidth: stroke).frame(width: s.width, height: s.height)
        case .rectangle:
            RoundedRectangle(cornerRadius: DesignTokens.Shape.cornerRadius(for: .rectangle, height: s.height), style: .continuous)
                .stroke(Color.primary, lineWidth: stroke).frame(width: s.width, height: s.height)
        case .square:
            SquareShape().stroke(Color.primary, lineWidth: stroke).frame(width: s.width, height: s.height)
        case .container:
            // v60: mini Lucidchart-container — färgad header-remsa + ljus kropp + solid ram.
            VStack(spacing: 0) {
                Rectangle().fill(Color.primary).frame(height: max(4, s.height * 0.30))
                Rectangle().fill(Color.primary.opacity(0.06))
            }
            .frame(width: s.width, height: s.height)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Shape.cornerRadius(for: .container, height: s.height), style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DesignTokens.Shape.cornerRadius(for: .container, height: s.height), style: .continuous).stroke(Color.primary, lineWidth: stroke))
        case .diamond:
            DiamondShape().stroke(Color.primary, lineWidth: stroke).frame(width: s.width, height: s.height)
        case .processArrow:
            ProcessArrowShape().stroke(Color.primary, lineWidth: stroke).frame(width: s.width, height: s.height)
        case .octagon:
            OctagonShape().stroke(Color.primary, lineWidth: stroke).frame(width: s.width, height: s.height)
        case .phoneFrame:
            PhoneFrameShape().stroke(Color.primary, lineWidth: stroke).frame(width: s.width, height: s.height)
        case .triangle:
            TriangleShape().stroke(Color.primary, lineWidth: stroke).frame(width: s.width, height: s.height)
        default:
            EmptyView()
        }
    }

    /// v34: shapeChip använder MANUELL DragGesture(coordinateSpace: .global)
    /// — Apple's .draggable + .dropDestination fungerar inte pålitligt inuti
    /// UIViewRepresentable runt UIScrollView (iOS drag-system kan inte alltid
    /// koppla draggable-source till dropDestination-target genom UIKit-wrappers).
    ///
    /// Flöde:
    /// 1. Chip's DragGesture.onChanged sätter chipDragState.activeType + location
    /// 2. ContentView ritar flytande chip-preview vid location
    /// 3. .onEnded: ContentView läser location, konverterar via viewportState
    ///    och anropar handleDrop. Eller chipsens egen onEnded gör det direkt.
    func shapeChip(_ type: ShapeType,
                   _ system: String,
                   accId: String,
                   onTap: @escaping () -> Void) -> some View {
        ChipFace(systemImage: system)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 8, coordinateSpace: .global)
                    .onChanged { value in
                        if chipDragState.activeType != type {
                            chipDragState.activeType = type
                        }
                        chipDragState.globalLocation = value.location
                    }
                    .onEnded { value in
                        // SYNKRONT: läs viewportState (UIScrollView's offset/scale/frame)
                        // och konvertera global drop-position → canvas-koord. Eftersom
                        // viewportState uppdateras SYNKRONT i delegate-callbacks läser
                        // vi exakt det värde som scrollViewen visar just nu — ingen race.
                        let global = value.location
                        chipDragState.globalLocation = global
                        chipDragState.activeType = nil
                        // Släpp inom canvas → kalla onDropShape med canvas-koord.
                        // Släpp utanför → ingen åtgärd (drag avbryts).
                        if viewportState.isInsideCanvas(global),
                           let canvasPoint = viewportState.canvasPoint(forGlobal: global) {
                            onDropShape(type, canvasPoint)
                        }
                    }
            )
            .onTapGesture { onTap() }
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(Text(a11yLabel(for: accId)))
            .accessibilityIdentifier(accId)
    }

    /// Generic shapeChip som tar en valfri face-view (används t.ex. för diamant med custom-ritad form).
    @ViewBuilder
    func shapeChipGeneric<F: View>(
        type: ShapeType,
        accId: String,
        onTap: @escaping () -> Void,
        @ViewBuilder face: () -> F
    ) -> some View {
        face()
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 8, coordinateSpace: .global)
                    .onChanged { value in
                        if chipDragState.activeType != type {
                            chipDragState.activeType = type
                        }
                        chipDragState.globalLocation = value.location
                    }
                    .onEnded { value in
                        let global = value.location
                        chipDragState.globalLocation = global
                        chipDragState.activeType = nil
                        if viewportState.isInsideCanvas(global),
                           let canvasPoint = viewportState.canvasPoint(forGlobal: global) {
                            onDropShape(type, canvasPoint)
                        }
                    }
            )
            .onTapGesture { onTap() }
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(Text(a11yLabel(for: accId)))
            .accessibilityIdentifier(accId)
    }

    /// v68: liten etikett under ett verktygs-chip (Kims fynd 3). Samma kompakta
    /// font som flödes-chipsen, ryms under ikonen utan att ta plats.
    @ViewBuilder
    func chipLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 8.5, weight: .medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .frame(width: 52)
    }

    /// v50.7 UX-001/010/013: människo-läsbara VoiceOver-labels per accId.
    /// Utan dessa läste VoiceOver råa SF Symbol-namn ("swatchpalette") eller
    /// chip-id:t ("chip circle"). accId behålls separat för UI-tester.
    func a11yLabel(for accId: String) -> String {
        switch accId {
        case "toolbar.shapes": return "Former"
        case "toolbar.packs": return "Formpaket"
        case "toolbar.colors": return "Färg"
        case "toolbar.textStyles": return "Textstil"
        case "toolbar.marker": return "Markera flera"
        case "toolbar.undo": return "Ångra"
        case "toolbar.redo": return "Gör om"
        case "toolbar.zoom": return "Zooma till 100 procent"
        case "chip.circle": return "Cirkel"
        case "chip.rectangle": return "Rektangel"
        case "chip.square": return "Kvadrat"
        case "chip.diamond": return "Romb"
        case "chip.pill": return "Kapsel"
        case "chip.processArrow": return "Processpil"
        case "chip.container": return "Behållare"
        case "chip.table": return "Tabell"
        case "chip.link": return "Hopplänk"
        case "chip.line": return "Linje"
        case "chip.octagon": return "Åttahörning"
        case "chip.triangle": return "Triangel"
        case "chip.emoji": return "Emoji"
        case "chip.phoneFrame": return "iPhone-ram"
        case "chip.notepopup": return "Visa anteckningar"
        default:
            if accId.hasPrefix("chip.pack.") || accId.hasPrefix("toggle.pack.") { return "Formpaket" }
            return accId
        }
    }
}

/// Återanvänd chip-yta (glas-bubbla) för shape-chips.
struct ChipFace: View {
    let systemImage: String
    var larger: Bool = false

    var body: some View {
        Image(systemName: systemImage)
            .font(larger ? .title2 : .title3)
            .foregroundStyle(Color.primary)
            // v33 polish: small chip 40→44 så fingret träffar bättre på iPhone
            .frame(width: larger ? 56 : 44, height: larger ? 56 : 44)
            .background(Circle().fill(.ultraThinMaterial))
            .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
            .contentShape(Circle())
    }
}
