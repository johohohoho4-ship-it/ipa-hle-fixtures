import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testCollectionsChecksPass() {
        let app = XCUIApplication()
        app.launch()

        let title = app.staticTexts["collections.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 15), "The collections fixture must appear")

        let status = app.staticTexts["collections.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertEqual(status.label, "COLLECTIONS_OK")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "swift-collections-all-checks-passed"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
