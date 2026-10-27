import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testInvalidationCountsBodyEvaluations() {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["swi.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20))
        expectation(for: NSPredicate(format: "label == %@", "SWI_DONE"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "swiftui-invalidation-complete"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
