import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func shot(_ app: XCUIApplication, _ name: String) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testObservableStateReacts() {
        let app = XCUIApplication()
        app.launch()

        let count = app.staticTexts["obs.count"]
        XCTAssertTrue(count.waitForExistence(timeout: 15), "The observable view must appear")
        XCTAssertEqual(count.label, "Count: 0")
        XCTAssertFalse(app.staticTexts["obs.detail"].exists)

        app.buttons["obs.increment"].tap()
        app.buttons["obs.increment"].tap()
        XCTAssertEqual(count.label, "Count: 2")
        XCTAssertTrue(app.staticTexts["obs.row.Row 2"].exists)

        app.buttons["obs.track"].tap()
        app.buttons["obs.increment"].tap()
        XCTAssertEqual(count.label, "Count: 3")
        app.buttons["obs.decrement"].tap()
        XCTAssertEqual(count.label, "Count: 2")

        app.switches["obs.toggle"].tap()
        XCTAssertTrue(app.staticTexts["obs.detail"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["obs.detail"].label.contains("2"))

        shot(app, "swiftui-observable-end")
        app.buttons["obs.finish"].tap()
    }
}
