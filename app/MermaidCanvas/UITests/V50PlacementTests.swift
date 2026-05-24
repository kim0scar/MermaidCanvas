import XCTest

/// v50: visuell placerings-bugjakt. Ett test per scenario från
/// V50PlacementMatrix.md. Varje test startar appen med ett `-uitest-place-NN-*`
/// launch-arg och tar en screenshot. Inga XCTAssert — granskningen sker
/// efteråt av en sub-agent som jämför screenshot mot förväntad placering.
final class V50PlacementTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    @MainActor
    private func runScenario(_ slug: String) {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-place-\(slug)"]
        app.launch()
        // Vänta så modellen hinner bygga upp scenariot (0.3s asyncAfter i ContentView).
        sleep(1)
        let att = XCTAttachment(screenshot: app.screenshot())
        att.name = "place_\(slug)"
        att.lifetime = .keepAlways
        add(att)
    }

    @MainActor func test_place_01_tight_horizontal()         { runScenario("01-tight-horizontal") }
    @MainActor func test_place_02_tight_vertical()           { runScenario("02-tight-vertical") }
    @MainActor func test_place_03_diagonal()                 { runScenario("03-diagonal") }
    @MainActor func test_place_04_very_close()               { runScenario("04-very-close") }
    @MainActor func test_place_05_arrowhead_8_directions()   { runScenario("05-arrowhead-8-directions") }
    @MainActor func test_place_06_arrowhead_on_diamond()     { runScenario("06-arrowhead-on-diamond") }
    @MainActor func test_place_07_arrowhead_on_pill()        { runScenario("07-arrowhead-on-pill") }
    @MainActor func test_place_08_arrow_each_shape_type()    { runScenario("08-arrow-each-shape-type") }
    @MainActor func test_place_09_processarrow_as_source()   { runScenario("09-processarrow-as-source") }
    @MainActor func test_place_10_container_as_target()      { runScenario("10-container-as-target") }
    @MainActor func test_place_11_collapsed_single()         { runScenario("11-collapsed-single") }
    @MainActor func test_place_12_collapsed_chain()          { runScenario("12-collapsed-chain") }
    @MainActor func test_place_13_minus_badge_position()     { runScenario("13-minus-badge-position") }
    @MainActor func test_place_14_bidir_with_label()         { runScenario("14-bidir-with-label") }
    @MainActor func test_place_15_dashed_edge()              { runScenario("15-dashed-edge") }
    @MainActor func test_place_16_backward_edge()            { runScenario("16-backward-edge") }
    @MainActor func test_place_17_container_with_3_children(){ runScenario("17-container-with-3-children") }
    @MainActor func test_place_18_nested_containers()        { runScenario("18-nested-containers") }
    @MainActor func test_place_19_child_outside_container()  { runScenario("19-child-outside-container") }
    @MainActor func test_place_20_multi_select_3_shapes()    { runScenario("20-multi-select-3-shapes") }
    @MainActor func test_place_21_multi_select_with_edges()  { runScenario("21-multi-select-with-edges") }
    @MainActor func test_place_22_edge_after_resize()        { runScenario("22-edge-after-resize") }
    @MainActor func test_place_23_edge_with_label_curved()   { runScenario("23-edge-with-label-curved") }
    // v50.3 nya scenarier (R3, R5, R1, R4, F-6)
    @MainActor func test_place_29_container_with_label()     { runScenario("29-container-with-label") }
    @MainActor func test_place_30_marker_mode_active()       { runScenario("30-marker-mode-active") }
    @MainActor func test_place_31_processarrow_isolated()    { runScenario("31-processarrow-isolated") }
    @MainActor func test_place_32_arrowheads_8_dirs()        { runScenario("32-arrowheads-8-dirs") }
    @MainActor func test_place_33_selected_pill()            { runScenario("33-selected-pill") }
    @MainActor func test_place_34_selected_diamond()         { runScenario("34-selected-diamond") }
}
