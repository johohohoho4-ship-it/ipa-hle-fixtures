import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testCustomExecutorTaskLocalAndCancellation() {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["concurrency3.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20))
        expectation(for: NSPredicate(format: "label == %@", "CC3_DONE"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "swift-concurrency-3-complete"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
