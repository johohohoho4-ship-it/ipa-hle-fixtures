import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testNamedColorFixtureReportsItsObservations() {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["nc.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20), "The named-colors fixture must appear")
        expectation(for: NSPredicate(format: "label == %@", "ready"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "named-colors-start"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
