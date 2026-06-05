import SwiftUI

/// v50.7 UX-003: tomt-tillstånd. Vägledning för förstagångsanvändare på tom canvas.
/// Rent visuellt — anroparen sätter `.allowsHitTesting(false)` så inga gester blockeras.
/// Kort text, rundad font, sekundär färg (Kim: visuell, dyslexi → visa hellre än förklara).
struct EmptyCanvasHint: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "hand.point.up.left")
                .font(.system(size: 40, weight: .light))
            Text("Börja här")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
            (Text("Tryck på ")
             + Text(Image(systemName: "square.on.circle"))
             + Text(" Former uppe till vänster och välj en form."))
                .font(.system(size: 16, design: .rounded))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
            // v61 (UX-009): pilar är halva språket — berätta var de skapas.
            (Text("Pil: markera en form och dra från ")
             + Text(Image(systemName: "arrow.up.right.circle"))
             + Text(" handtaget."))
                .font(.system(size: 14, design: .rounded))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
        .foregroundStyle(.secondary)
        .padding(28)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tom canvas. Tryck på Former uppe till vänster för att lägga till en form. Skapa pil genom att markera en form och dra från pilhandtaget.")
    }
}
