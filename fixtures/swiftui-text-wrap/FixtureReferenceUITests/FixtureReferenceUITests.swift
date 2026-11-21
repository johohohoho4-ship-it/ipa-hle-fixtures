import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testTextWrapReportsEveryFrame() {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["wrap.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20), "The text wrap fixture must appear")
        expectation(for: NSPredicate(format: "label == %@", "SWW_DONE"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "swiftui-text-wrap-complete"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
