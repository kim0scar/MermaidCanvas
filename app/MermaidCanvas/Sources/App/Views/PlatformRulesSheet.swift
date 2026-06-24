import SwiftUI

/// v27: Visar reglerna (lexicon-MD-filen) för aktuell plattform.
struct PlatformRulesSheet: View {
    let platform: Platform
    var onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(PlatformRules.text(for: platform))
                    .font(.system(size: 13, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
            .navigationTitle("Regler — \(platform.displayName)")
            .inlineNavTitle()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Stäng", action: onClose)
                }
            }
        }
    }
}
