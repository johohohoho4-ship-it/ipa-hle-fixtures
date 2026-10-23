import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testIndexPathFixtureReportsItsObservations() {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["ip.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20), "The IndexPath fixture must appear")
        expectation(for: NSPredicate(format: "label == %@", "ready"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "swift-indexpath-start"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
