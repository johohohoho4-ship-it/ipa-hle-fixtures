import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testCombineBasicsRunToCompletion() {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["combine.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20))
        expectation(for: NSPredicate(format: "label == %@", "CMB_DONE"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "combine-basics-complete"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
