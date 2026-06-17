// Container-barn — utbruten ur CanvasModel (MA spår A steg 14–18). @Published-fasaden ligger kvar i CanvasModel.swift → rerender oförändrad. Beteende verbatim.
import Foundation
import SwiftUI

extension CanvasModel {
    /// v47: returnerar former som är barn till en container.
    /// **Explicit-först:** former vars `childOfContainerId` matchar räknas alltid med,
    /// oavsett position. Detta är robust mot att container drar barnen utanför sina
    /// bounds under flytt.
    /// **Fallback:** för bakåtkompatibilitet med v46-och-äldre data där fältet saknas
    /// (nil-värde), räknas också former vars position ligger innanför containerns
    /// bounds OCH som inte tillhör någon annan container.
    func shapesInside(container: ShapeNode) -> [ShapeNode] {
        let w = ShapeGeometry.width(for: container)
        let h = ShapeGeometry.height(for: container)
        let rect = CGRect(x: container.position.x - w/2,
                          y: container.position.y - h/2,
                          width: w, height: h)
        return shapes.filter { s in
            guard s.id != container.id, s.type != .container else { return false }
            // Explicit-först
            if let explicitParent = s.childOfContainerId {
                return explicitParent == container.id
            }
            // Fallback: position innanför + ingen annan explicit förälder
            return rect.contains(s.position)
        }
    }

    /// v47: detektera vilken container en form ska tillhöra baserat på sin position.
    /// Anropas typiskt efter att en form har flyttats (drag-end). Sätter eller tömmer
    /// `childOfContainerId` automatiskt. Vid överlappande containrar väljs den
    /// **senast tillagda** (visuellt på toppen i z-ordning).
    func assignContainerForShape(_ shapeId: UUID) {
        guard let shapeIdx = shapes.firstIndex(where: { $0.id == shapeId }) else { return }
        let shape = shapes[shapeIdx]
        // Containrar är inte själva barn av andra containrar.
        guard shape.type != .container else { return }
        let pos = shape.position
        // Iterera baklänges för att välja toppen vid överlapp.
        var newParent: UUID? = nil
        for cs in shapes.reversed() where cs.type == .container {
            let w = ShapeGeometry.width(for: cs)
            let h = ShapeGeometry.height(for: cs)
            let r = CGRect(x: cs.position.x - w/2,
                           y: cs.position.y - h/2,
                           width: w, height: h)
            if r.contains(pos) {
                newParent = cs.id
                break
            }
        }
        if shapes[shapeIdx].childOfContainerId != newParent {
            shapes[shapeIdx].childOfContainerId = newParent
        }
    }

    /// v60: container "adopterar" alla icke-container-former vars position ligger inom
    /// dess bounds → sätter childOfContainerId. Kallas vid container-drag-slut, så att
    /// dra containern ÖVER former gör dem till barn (de följer sedan med vid flytt).
    func claimChildren(forContainer containerId: UUID) {
        guard let container = shapes.first(where: { $0.id == containerId }),
              container.type == .container else { return }
        let w = ShapeGeometry.width(for: container)
        let h = ShapeGeometry.height(for: container)
        let rect = CGRect(x: container.position.x - w / 2,
                          y: container.position.y - h / 2,
                          width: w, height: h)
        for i in shapes.indices {
            guard shapes[i].id != containerId, shapes[i].type != .container else { continue }
            if rect.contains(shapes[i].position) {
                shapes[i].childOfContainerId = containerId
            }
        }
    }

    /// v44: flytta alla former inuti en container med givet delta.
    /// Anropas live under drag av container så inneliggande former följer med.
    func moveContainerChildren(containerId: UUID, by delta: CGSize) {
        guard let container = shapes.first(where: { $0.id == containerId }) else { return }
        let inside = shapesInside(container: container)
        for child in inside {
            if let i = shapes.firstIndex(where: { $0.id == child.id }) {
                shapes[i].position.x += delta.width
                shapes[i].position.y += delta.height
            }
        }
    }
}
