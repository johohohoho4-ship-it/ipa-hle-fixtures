import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testCancellationContinuationsAndTaskLocal() {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["concurrency.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20))
        expectation(for: NSPredicate(format: "label == %@", "CONC2_OK"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "swift-concurrency-2-complete"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
