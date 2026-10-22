import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testLayoutReportsEveryFrame() {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["layout.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20), "The layout fixture must appear")
        expectation(for: NSPredicate(format: "label == %@", "SWL_DONE"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "swiftui-layout-complete"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
