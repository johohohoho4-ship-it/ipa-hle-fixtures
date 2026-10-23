import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testSymbolsReportFrames() {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["symbols.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20), "The symbols fixture must appear")
        expectation(for: NSPredicate(format: "label == %@", "ready"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "swiftui-symbols-complete"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
