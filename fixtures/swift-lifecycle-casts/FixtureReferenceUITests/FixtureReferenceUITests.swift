import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testHostingLifecycleAndCasts() {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["cast.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20))
        expectation(for: NSPredicate(format: "label == %@", "CAST_DONE"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "swift-lifecycle-casts-complete"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testUnconditionalGenericCastTraps() {
        let app = XCUIApplication()
        app.launchEnvironment = ["CAST_TRAP_ONLY": "1"]
        app.launch()

        let status = app.staticTexts["cast.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20))
        expectation(for: NSPredicate(format: "label == %@", "TRAP_READY"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        app.buttons["cast.crash"].tap()
        XCTAssertTrue(app.wait(for: .notRunning, timeout: 10))
    }
}
