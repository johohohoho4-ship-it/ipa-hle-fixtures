import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testFoundationChecksPass() {
        let app = XCUIApplication()
        app.launch()

        let title = app.staticTexts["foundation.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 15), "The foundation fixture must appear")

        let status = app.staticTexts["foundation.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertEqual(status.label, "FOUNDATION_OK")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "swift-foundation-all-checks-passed"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
