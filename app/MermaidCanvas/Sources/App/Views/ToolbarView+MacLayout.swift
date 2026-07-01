import SwiftUI

/// 1.5.7 (Kim: "menyerna ser inte bra ut" på Mac): den horisontella verktygsraden byggdes för
/// smal iPhone-bredd med en greedy Spacer mitt i → i ett brett Mac-fönster spreds grupperna ut till
/// varsin kant med en jättelucka i mitten. Här bor Mac-anpassningen (utbruten så ToolbarView.swift
/// inte växer förbi R5-taket). iOS-grenarna återger EXAKT det gamla beteendet → iPhone oförändrat.
extension ToolbarView {
    /// Mellanrum mellan verktygs-gruppen och zoom/historik-gruppen i den horisontella raden.
    /// iOS: greedy Spacer → grupperna hamnar vid varsin kant (oförändrat sedan v60).
    /// Mac: fast lucka; hela raden vänsterjusteras i stället (`macToolbarLeading()`).
    @ViewBuilder
    func primaryGroupSpacer(vertical: Bool) -> some View {
        if !vertical {
            #if os(macOS)
            Spacer().frame(width: 24)
            #else
            Spacer(minLength: 0)
            #endif
        }
    }
}

extension View {
    /// Mac: fyll fönster-bredden men vänsterjustera innehållet — så `appBackground`-raden täcker
    /// hela toppen medan kontrollerna sitter samlade till vänster (Mac-konvention), inte utspridda.
    /// iOS: no-op (raden fyller redan bredden via sin greedy Spacer).
    @ViewBuilder
    func macToolbarLeading() -> some View {
        #if os(macOS)
        frame(maxWidth: .infinity, alignment: .leading)
        #else
        self
        #endif
    }
}
