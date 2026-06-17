import SwiftUI

/// Tabell-bakgrund (grid + cellinnehåll). Används av ShapeView för ShapeType.table.
/// (MA spår A steg 4: flyttad ur CanvasView; `private` → `internal`.)
struct TableShapeBackground: View {
    var rows: Int
    var cols: Int
    var cells: [[String]]
    var fill: Color
    var stroke: Color

    var body: some View {
        GeometryReader { geo in
            // v50.5 (v5) H1/H2: tabell-data redigeras tvåvägs via markdown —
            // ett handredigerat 0 i rows/cols gav `1..<0` Range-krasch + div-by-zero.
            // Klampa till minst 1 här så formen alltid är ritbar.
            let rows = max(1, self.rows)
            let cols = max(1, self.cols)
            let cellW = geo.size.width / CGFloat(cols)
            let cellH = geo.size.height / CGFloat(rows)
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(fill.opacity(0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(stroke, lineWidth: 1.5)
                    )
                // Cellinnehåll
                ForEach(0..<rows, id: \.self) { row in
                    ForEach(0..<cols, id: \.self) { col in
                        let text = row < cells.count && col < cells[row].count ? cells[row][col] : ""
                        if !text.isEmpty {
                            Text(text)
                                .font(.system(size: max(8, min(cellH * 0.4, 12))))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .foregroundStyle(stroke)
                                .frame(width: cellW, height: cellH)
                                .position(x: cellW * (CGFloat(col) + 0.5),
                                          y: cellH * (CGFloat(row) + 0.5))
                                .allowsHitTesting(false)
                        }
                    }
                }
                // Gridlinjer
                Path { p in
                    for r in 1..<rows {
                        let y = cellH * CGFloat(r)
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                    for c in 1..<cols {
                        let x = cellW * CGFloat(c)
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: geo.size.height))
                    }
                }
                .stroke(stroke.opacity(0.5), lineWidth: 1)
            }
        }
    }
}

/// v38: länk-bubbla — alltid accentfärg (tidigare vit-på-vit osynlig).
struct JumpLinkShapeBackground: View {
    var number: Int

    var body: some View {
        ZStack {
            Circle().fill(Color.accentColor)
            Circle().stroke(Color.white.opacity(0.35), lineWidth: 1.5)
            VStack(spacing: 1) {
                Image(systemName: "link")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                Text("\(number)")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white)
            }
        }
    }
}
