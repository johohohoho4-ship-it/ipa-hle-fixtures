import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testUnsafeContinuationsPriorityAndThrowingGroupWork() {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["concurrency4.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20))
        expectation(for: NSPredicate(format: "label == %@", "CC4_DONE"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "swift-concurrency-4-complete"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
