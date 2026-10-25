import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testGroupCancellationQueries() {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["concurrency5.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20))
        expectation(for: NSPredicate(format: "label == %@", "CC5_DONE"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "swift-concurrency-5-complete"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
