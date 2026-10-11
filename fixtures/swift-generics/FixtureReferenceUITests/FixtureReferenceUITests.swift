import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testGenericsChecksPass() {
        let app = XCUIApplication()
        app.launch()

        let title = app.staticTexts["generics.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 15), "The generics fixture must appear")

        let status = app.staticTexts["generics.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertEqual(status.label, "GENERICS_OK")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "swift-generics-all-checks-passed"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
