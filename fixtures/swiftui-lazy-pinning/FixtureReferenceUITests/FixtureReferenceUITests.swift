import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testLazyContainersReportFlagsAndFrames() {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["pin.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20), "The pinning fixture must appear")
        expectation(for: NSPredicate(format: "label == %@", "ready"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "swiftui-lazy-pinning"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
