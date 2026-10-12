import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// Frames in points of the window, as the HLE layout must reproduce them.
    private func logFrame(_ element: XCUIElement, _ name: String) {
        let f = element.frame
        print("SWU_UI_FRAME \(name) x=\(f.origin.x) y=\(f.origin.y) w=\(f.size.width) h=\(f.size.height)")
    }

    private func shot(_ app: XCUIApplication, _ name: String) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testStateReactsToTaps() {
        let app = XCUIApplication()
        app.launch()

        let count = app.staticTexts["state.count"]
        XCTAssertTrue(count.waitForExistence(timeout: 15), "The SwiftUI state view must appear")
        XCTAssertEqual(count.label, "Count: 0")
        XCTAssertEqual(app.staticTexts["state.name"].label, "Name: Ada")
        XCTAssertFalse(app.staticTexts["state.detail"].exists)
        for name in ["count", "decrement", "increment", "toggle", "name", "rename"] {
            let element = app.descendants(matching: .any)["state.\(name)"]
            logFrame(element, name)
        }
        shot(app, "swiftui-state-start")

        // @State: two increments, one decrement; ForEach follows the count.
        app.buttons["state.increment"].tap()
        app.buttons["state.increment"].tap()
        XCTAssertEqual(count.label, "Count: 2")
        XCTAssertTrue(app.staticTexts["state.row.1"].exists)
        logFrame(app.staticTexts["state.row.0"], "row0")
        logFrame(app.staticTexts["state.row.1"], "row1")
        shot(app, "swiftui-state-count-2")
        app.buttons["state.decrement"].tap()
        XCTAssertEqual(count.label, "Count: 1")
        XCTAssertFalse(app.staticTexts["state.row.1"].exists)

        // @Binding: the child button flips the parent's state and the conditional text.
        app.buttons["state.toggle"].tap()
        XCTAssertTrue(app.staticTexts["state.detail"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.buttons["state.toggle"].label, "Hide detail")

        // @StateObject/@ObservedObject: a @Published change redraws the child.
        app.buttons["state.rename"].tap()
        XCTAssertEqual(app.staticTexts["state.name"].label, "Name: Grace")
        shot(app, "swiftui-state-end")
    }
}
