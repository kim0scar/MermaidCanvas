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

    /// Dra-handtag: tap ELLER vertikal-drag fäller in sekundärraden. Vertikal-only-tröskel
    /// (minDist 8, > 12) så horisontell scroll/tryck i raden inte stjäls.
    @ViewBuilder
    var grabberHandle: some View {
        Capsule()
            .fill(Color.appTertiaryLabel)
            .frame(width: 38, height: 5)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
            .onTapGesture { dismissSecondary() }
            .gesture(
                DragGesture(minimumDistance: 8).onEnded { v in
                    if abs(v.translation.height) > 12 { dismissSecondary() }
                }
            )
            .accessibilityIdentifier("toolbar.grabber")
            .accessibilityLabel("Fäll in menyraden")
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
