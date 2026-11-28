import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testTextModifiersReportEveryFrame() {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["modifiers.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20), "The text modifiers fixture must appear")
        expectation(for: NSPredicate(format: "label == %@", "SWM_DONE"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "swiftui-text-modifiers-complete"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
