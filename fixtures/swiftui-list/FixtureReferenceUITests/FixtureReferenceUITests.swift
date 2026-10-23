import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testListsReportFramesAndSwipeOnce() {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["list.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20), "The list fixture must appear")
        expectation(for: NSPredicate(format: "label == %@", "ready"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        let list = app.tables.firstMatch
        XCTAssertTrue(list.exists, "The measured List must be a table")
        list.swipeUp()

        let after = app.buttons["list.after"]
        XCTAssertTrue(after.exists && after.isHittable, "The after-scroll button must be reachable")
        after.tap()
        expectation(for: NSPredicate(format: "label == %@", "after"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "swiftui-list-after-scroll"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
