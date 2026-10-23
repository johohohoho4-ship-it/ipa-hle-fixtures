import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testViewsReportFramesAndTap() {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["views.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20), "The views fixture must appear")
        expectation(for: NSPredicate(format: "label == %@", "ready"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        let button = app.buttons["views.button"]
        XCTAssertTrue(button.exists, "The measured button must be queryable")
        button.tap()

        expectation(for: NSPredicate(format: "label == %@", "SWV_DONE"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "swiftui-views-complete"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
