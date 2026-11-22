import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testTwoHostsAndRootReplacement() {
        let app = XCUIApplication()
        app.launch()

        let left = app.buttons["hc.left.button"]
        XCTAssertTrue(left.waitForExistence(timeout: 20), "The left hosting button must appear")
        left.tap()

        let changed = NSPredicate(format: "label == %@", "Left 1")
        expectation(for: changed, evaluatedWith: left)
        waitForExpectations(timeout: 5)

        XCTAssertEqual(app.staticTexts["hc.right.title"].label, "Right")
        XCTAssertEqual(app.staticTexts["hc.right.value"].label, "static")

        app.buttons["hc.replace"].tap()
        XCTAssertTrue(app.staticTexts["hc.replaced.title"].waitForExistence(timeout: 5))

        let status = app.staticTexts["hc.status"]
        let done = NSPredicate(format: "label == %@", "HC_DONE")
        expectation(for: done, evaluatedWith: status)
        waitForExpectations(timeout: 5)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "hosting-controller-after-replace"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
