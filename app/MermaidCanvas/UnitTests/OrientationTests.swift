import XCTest
import UIKit
@testable import MermaidCanvas

/// v60.1: regressionsskydd för forcerad rotation. Det ursprungliga felet (svart nedre
/// halva i landskap på enhet / sidledes i sim) berodde på att `requestGeometryUpdate`
/// fick den TVETYDIGA `.landscape`-masken (landscapeLeft|landscapeRight) → iOS kunde
/// inte avgöra vilket håll och roterade inte. Geometry-anropet måste använda en KONKRET
/// orientering. Detta test låser fast det.
final class OrientationTests: XCTestCase {

    func test_geometryOrientations_landscape_isConcrete() {
        // Får INTE vara den tvetydiga .landscape-masken (= left|right).
        XCTAssertEqual(OrientationMode.landscape.geometryOrientations, .landscapeRight)
        XCTAssertNotEqual(OrientationMode.landscape.geometryOrientations, .landscape)
    }

    func test_geometryOrientations_portrait_isPortrait() {
        XCTAssertEqual(OrientationMode.portrait.geometryOrientations, .portrait)
    }

    func test_supportedMask_allowsLandscape() {
        // supportedInterfaceOrientations får vara bred (.landscape) så användaren kan
        // tvinga endera landskapsriktningen; det är geometry-anropet som ska vara konkret.
        XCTAssertEqual(OrientationMode.landscape.mask, .landscape)
        XCTAssertEqual(OrientationMode.portrait.mask, .portrait)
    }
}
