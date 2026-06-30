import SwiftUI

/// 1.4: sekundärraden + ett "dra-handtag" (grabber) överst som fäller in raden.
/// Kim slipper leta upp exakt vilken primär-knapp som öppnade raden — dra eller tryck
/// på handtaget = skicka in den. Utbruten ur ToolbarView.swift (R5: ToolbarView är frozen).
extension ToolbarView {
    @ViewBuilder
    func secondaryRowView(_ row: SecondaryToolbarRow) -> some View {
        VStack(spacing: 2) {
            grabberHandle
            HStack(spacing: 8) {
                switch row {
                case .shapes:      shapesSecondary
                case .colors:      colorsSecondary
                case .textStyles:  textStylesSecondary
                case .multiSelect: multiSelectSecondary
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.top, 2)
        .padding(.bottom, 6)
        .background(Color.appSecondaryBackground)
    }

    /// 1.5.5 (Kim): tydligt stäng-grepp LÄNGST UT (trailing) på rullgardinen — speglar "Klar"
    /// som sitter längst ut i snabb-fältet. Det gamla lilla centrerade strecket var svårt att se/nå.
    /// Tap eller svep-upp ("rulla upp gardinen") stänger raden. Vertikal-tröskel så horisontell
    /// scroll/tryck i raden inte stjäls.
    @ViewBuilder
    var grabberHandle: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            Image(systemName: "chevron.compact.up")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.secondary)
                .frame(width: 64, height: 26)
                .contentShape(Rectangle())
                .onTapGesture { dismissSecondary() }
                .gesture(
                    DragGesture(minimumDistance: 8).onEnded { v in
                        if abs(v.translation.height) > 12 { dismissSecondary() }
                    }
                )
                .accessibilityIdentifier("toolbar.grabber")
                .accessibilityLabel("Stäng menyraden")
        }
    }

    /// Fäller in sekundärraden — samma animation + haptik som toggle-knappen. I markeringsläge
    /// (multiSelect-raden tvingas av markerMode) stänger den i stället markeringsläget.
    func dismissSecondary() {
        Haptics.impact()
        withAnimation(.smooth(duration: 0.25)) {
            if model.markerMode { model.toggleMarkerMode() } else { secondaryRow = nil }
        }
    }
}
