import SwiftUI

/// Visar reglerna (lexicon-MD-filen) för aktuell plattform.
/// MD-filerna bundlas som resource i appen så Kim alltid kan läsa dem på iPhonen.
struct PlatformRulesSheet: View {
    let specType: SpecType
    var onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(PlatformRules.text(for: specType))
                    .font(.system(size: 13, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
            .navigationTitle("Regler — \(specType.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Stäng", action: onClose)
                }
            }
        }
    }
}
