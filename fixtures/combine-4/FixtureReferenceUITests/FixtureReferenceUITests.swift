import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testCombine4RunToCompletion() {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["combine4.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20))
        expectation(for: NSPredicate(format: "label == %@", "CMB4_DONE"), evaluatedWith: status)
        waitForExpectations(timeout: 30)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "combine-4-complete"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
