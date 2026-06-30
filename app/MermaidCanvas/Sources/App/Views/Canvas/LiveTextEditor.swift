#if os(iOS)
import SwiftUI
import UIKit

/// Vilken markör som ritas i vänster-marginalen under live-redigering.
enum ListMarkerKind { case none, bullet, numbered }

/// Bug 3 (Kims order): live-redigering I formen. En `UITextView` som RITAR punkt/nummer/
/// indrag i vänster-marginalen medan textbufferten hålls REN (`shape.label` får aldrig "• ").
/// Markörerna är ritade → markören (cursor) beter sig naturligt, inget hopp. Ingen ny bärare:
/// lista/indrag round-trippar redan via flaggor (regel 15 trivialt grön). FormattingBar bor i
/// `inputAccessoryView` (SwiftUIs keyboard-toolbar visas inte för en UITextView-first-responder).
struct LiveTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var isEditing: Bool
    var font: UIFont
    var textColor: UIColor
    var alignment: NSTextAlignment
    var underline: Bool
    var listKind: ListMarkerKind
    var indentLevel: Int
    var onEndEdit: () -> Void
    // AnyView (ej generisk) MED FLIT: en generisk Coordinator hamnar i generisk kontext och
    // kan då inte exponera @objc-delegatmetoderna UIKit anropar (lärdom från 1.5.3-bygget).
    var accessory: () -> AnyView

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> ListMarkerTextView {
        let tv = ListMarkerTextView()
        tv.delegate = context.coordinator
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.textContainer.lineFragmentPadding = 0
        // Autocorrect AV — SwiftUIs `.autocorrectionDisabled()` ärvs INTE till UIKit (Kims
        // "PillX→Pilla"-fynd). Måste sättas direkt på text-vyn.
        tv.autocorrectionType = .no
        tv.spellCheckingType = .no
        tv.smartDashesType = .no
        tv.smartQuotesType = .no
        tv.autocapitalizationType = .sentences

        // FormattingBar ovanför tangentbordet via UIHostingController.
        let host = UIHostingController(rootView: accessory())
        host.view.backgroundColor = UIColor.secondarySystemBackground
        host.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50)
        host.view.autoresizingMask = [.flexibleWidth]
        context.coordinator.accessoryHost = host
        tv.inputAccessoryView = host.view

        tv.text = text
        apply(tv)
        // Auto-fokus (vyn är inte i fönstret än → nästa runloop).
        DispatchQueue.main.async { tv.becomeFirstResponder() }
        return tv
    }

    func updateUIView(_ tv: ListMarkerTextView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.accessoryHost?.rootView = accessory()
        // Skriv bara texten om den FAKTISKT skiljer (annars markör-reset / oändlig loop).
        if tv.text != text { tv.text = text }
        apply(tv)
        if !isEditing && tv.isFirstResponder { tv.resignFirstResponder() }
    }

    private func apply(_ tv: ListMarkerTextView) {
        tv.font = font
        tv.textColor = textColor
        tv.textAlignment = alignment

        // Understruken över hela texten (bevara markeringen så markören inte hoppar).
        let sel = tv.selectedRange
        if tv.textStorage.length > 0 {
            let full = NSRange(location: 0, length: tv.textStorage.length)
            if underline {
                tv.textStorage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: full)
            } else {
                tv.textStorage.removeAttribute(.underlineStyle, range: full)
            }
            tv.selectedRange = sel
        }
        tv.typingAttributes[.underlineStyle] = underline ? NSUnderlineStyle.single.rawValue : 0

        // Marginal + markör-konfiguration.
        let step: CGFloat = 16
        let gutter: CGFloat = font.pointSize * 0.9 + 6
        let listActive = (listKind != .none)
        tv.markerKind = listKind
        tv.markerGutter = gutter
        tv.markerColor = textColor
        tv.markerFont = font

        var inset = tv.textContainerInset
        inset.left = 4 + CGFloat(max(0, indentLevel)) * step + (listActive ? gutter : 0)
        tv.textContainerInset = inset
        tv.setNeedsDisplay()
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: LiveTextEditor
        var accessoryHost: UIHostingController<AnyView>?
        init(_ parent: LiveTextEditor) { self.parent = parent }

        func textViewDidChange(_ tv: UITextView) {
            parent.text = tv.text
            tv.setNeedsDisplay()   // rita om markörer när rader läggs till/tas bort
        }
        func textViewDidEndEditing(_ tv: UITextView) {
            parent.isEditing = false
            parent.onEndEdit()
        }
    }
}

/// UITextView som ritar list-markörer (•/N.) i vänster-marginalen på FÖRSTA visuella raden
/// av varje paragraf. Texten i bufferten är ren — markörerna är bara ritade ovanpå.
final class ListMarkerTextView: UITextView {
    var markerKind: ListMarkerKind = .none
    var markerGutter: CGFloat = 18
    var markerColor: UIColor = .label
    var markerFont: UIFont = .systemFont(ofSize: 17)

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard markerKind != .none else { return }
        drawMarkers()
    }

    private func drawMarkers() {
        let lm = layoutManager
        let s = textStorage.string as NSString
        let attrs: [NSAttributedString.Key: Any] = [.font: markerFont, .foregroundColor: markerColor]

        var paraStart = 0
        var number = 1
        while paraStart <= s.length {
            let searchRange = NSRange(location: paraStart, length: s.length - paraStart)
            let nl = s.range(of: "\n", options: [], range: searchRange)
            if let lineRect = firstLineRect(forCharAt: paraStart, lm: lm) {
                let marker = markerKind == .numbered ? "\(number)." : "•"
                let size = (marker as NSString).size(withAttributes: attrs)
                // Markören HUGGER texten (lineFragmentUsedRect är alignment-medveten) så
                // "• text" hänger ihop oavsett vänster/center/höger → live ≈ visnings-läget.
                let textStartX = lineRect.minX + textContainerInset.left
                let x = max(2, textStartX - size.width - 5)
                let y = lineRect.midY + textContainerInset.top - size.height / 2
                (marker as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
            }
            number += 1
            if nl.location == NSNotFound { break }
            paraStart = nl.location + 1
        }
    }

    /// Rektangel för paragrafens första visuella rad (hanterar tom sista rad via extra-fragmentet).
    private func firstLineRect(forCharAt charIndex: Int, lm: NSLayoutManager) -> CGRect? {
        if charIndex >= textStorage.length {
            if lm.extraLineFragmentTextContainer != nil { return lm.extraLineFragmentUsedRect }
            guard lm.numberOfGlyphs > 0 else {
                return CGRect(x: 0, y: 0, width: 0, height: markerFont.lineHeight)
            }
            return lm.lineFragmentUsedRect(forGlyphAt: lm.numberOfGlyphs - 1, effectiveRange: nil)
        }
        let g = lm.glyphIndexForCharacter(at: charIndex)
        return lm.lineFragmentUsedRect(forGlyphAt: g, effectiveRange: nil)
    }
}
#endif
