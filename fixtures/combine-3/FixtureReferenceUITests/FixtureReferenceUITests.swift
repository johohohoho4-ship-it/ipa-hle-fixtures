import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testCombine3RunToCompletion() {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["combine3.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20))
        expectation(for: NSPredicate(format: "label == %@", "CMB3_DONE"), evaluatedWith: status)
        waitForExpectations(timeout: 30)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "combine-3-complete"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
