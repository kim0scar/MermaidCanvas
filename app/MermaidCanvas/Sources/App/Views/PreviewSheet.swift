import SwiftUI

/// Sheet som visar **Claudes översättning** av canvasen.
/// Sida vid sida-tanken: Kim ser sin canvas i appen, öppnar Preview för att se
/// hur kategorierna översätts till en faktisk iPhone-vy / lista / pipeline.
struct PreviewSheet: View {
    let shapes: [ShapeNode]
    let edges: [EdgeConnection]
    let canvasSize: CGSize
    let specType: SpecType
    var onClose: () -> Void

    var body: some View {
        NavigationStack {
            UIRenderer(
                shapes: shapes,
                edges: edges,
                canvasSize: canvasSize,
                specType: specType
            )
            .navigationTitle("Preview — \(specType.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Stäng", action: onClose)
                }
            }
        }
        .presentationDetents([.large])
    }
}
