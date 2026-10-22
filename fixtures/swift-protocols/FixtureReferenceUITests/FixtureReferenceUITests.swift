import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testProtocolChecksPass() {
        let app = XCUIApplication()
        app.launch()

        let title = app.staticTexts["protocols.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 15), "The protocols fixture must appear")

        let status = app.staticTexts["protocols.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        expectation(for: NSPredicate(format: "label == %@", "PRT_DONE"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "swift-protocols-complete"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
