import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testCombine2RunToCompletion() {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["combine2.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20))
        expectation(for: NSPredicate(format: "label == %@", "CMB2_DONE"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "combine-2-complete"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
