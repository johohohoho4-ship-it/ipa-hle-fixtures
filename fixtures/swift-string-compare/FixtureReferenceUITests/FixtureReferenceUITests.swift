import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testStringCompareWithSmolCheckPrefixAndNFC() {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["string-compare.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20))
        expectation(for: NSPredicate(format: "label == %@", "SC_DONE"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "swift-string-compare-complete"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
