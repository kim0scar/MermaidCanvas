#if os(iOS)
import SwiftUI
import UIKit

/// Scroll-hjälp för iOS-canvasen, utbruten ur ZoomableCanvas.swift (R5-ratchet):
/// (1) auto-scroll när en form dras nära kanten (v39), och
/// (2) 1.5.3 (Kim: "se din text") tangentbords-undvikning — lyft den redigerade
///     formen ovanför det mjuka tangentbordet istället för att gömma den bakom det.
extension ZoomableCanvas.Coordinator {

    // MARK: - Auto-scroll vid kant-drag (v39)

    func handleAutoScrollVelocity(_ velocity: CGSize) {
        if velocity == .zero {
            autoScrollTimer?.invalidate()
            autoScrollTimer = nil
        } else if autoScrollTimer == nil {
            autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
                guard let self, let sv = self.scrollView else { return }
                let vel = self.viewportState.autoScrollVelocity
                guard vel != .zero else { return }
                let dt: CGFloat = 1.0 / 60.0
                let dx = vel.width * dt
                let dy = vel.height * dt
                let maxX = max(0, sv.contentSize.width - sv.bounds.width)
                let maxY = max(0, sv.contentSize.height - sv.bounds.height)
                let newOffset = CGPoint(
                    x: min(max(0, sv.contentOffset.x + dx), maxX),
                    y: min(max(0, sv.contentOffset.y + dy), maxY)
                )
                sv.setContentOffset(newOffset, animated: false)
            }
        }
    }

    // MARK: - Tangentbords-undvikning (1.5.3)

    /// Registreras i init. (iOS 9+ avregistrerar selector-observers automatiskt vid dealloc.)
    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    /// Krymp scroll-området med tangentbordshöjden OCH scrolla den redigerade formen
    /// (first responder) upp så den syns ovanför tangentbordet.
    @objc func keyboardWillShow(_ note: Notification) {
        guard let sv = scrollView, let win = sv.window,
              let kbVal = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        else { return }
        let kbInWin = kbVal.cgRectValue
        let svFrameInWin = sv.convert(sv.bounds, to: win)
        let overlap = max(0, svFrameInWin.maxY - kbInWin.minY)
        guard overlap > 0 else { return }
        sv.contentInset.bottom = overlap
        sv.verticalScrollIndicatorInsets.bottom = overlap
        if let fr = sv.firstResponderInSubtree() {
            // +28pt luft så formen inte ligger klistrad mot tangentbordskanten.
            let rect = fr.convert(fr.bounds, to: sv).insetBy(dx: 0, dy: -28)
            sv.scrollRectToVisible(rect, animated: true)
        }
    }

    /// Återställ scroll-området när tangentbordet göms.
    @objc func keyboardWillHide(_ note: Notification) {
        guard let sv = scrollView else { return }
        sv.contentInset.bottom = 0
        sv.verticalScrollIndicatorInsets.bottom = 0
    }
}

private extension UIView {
    /// Hitta first responder i subträdet (den TextField som redigeras).
    func firstResponderInSubtree() -> UIView? {
        if isFirstResponder { return self }
        for sub in subviews {
            if let r = sub.firstResponderInSubtree() { return r }
        }
        return nil
    }
}
#endif
