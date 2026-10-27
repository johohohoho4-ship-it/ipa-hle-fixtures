import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testRealTabSwitchChangesTheSelection() {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["tab.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20))
        expectation(for: NSPredicate(format: "label == %@", "TAB_SELECTION 0"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        // A real tab-bar tap, not a state write from the app.
        let second = app.tabBars.buttons.element(boundBy: 1)
        XCTAssertTrue(second.waitForExistence(timeout: 10))
        second.tap()

        expectation(for: NSPredicate(format: "label == %@", "TAB_SELECTION 1"), evaluatedWith: status)
        waitForExpectations(timeout: 20)
        XCTAssertTrue(app.staticTexts["tab.two"].waitForExistence(timeout: 10))

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "swiftui-tabview-second-tab"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
