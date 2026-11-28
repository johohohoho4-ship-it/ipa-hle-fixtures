import XCTest

final class FixtureReferenceUITests: XCTestCase {
    func testLaunchesSimpleRSSReader() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "SimpleRSSReader must reach the foreground")

        XCTAssertTrue(app.tables.firstMatch.waitForExistence(timeout: 10),
                      "The news table must be visible")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-simplerssreader-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
