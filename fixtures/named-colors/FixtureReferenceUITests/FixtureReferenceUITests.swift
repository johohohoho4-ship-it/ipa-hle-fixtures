import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testNamedColorFixtureStarts() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "The named-colors fixture must stay in the foreground")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "named-colors-start"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
