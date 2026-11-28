import XCTest

final class FixtureReferenceUITests: XCTestCase {
    func testLaunchesHitList() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "HitList must reach the foreground")

        XCTAssertTrue(app.tables.firstMatch.waitForExistence(timeout: 10),
                      "The name table must be visible")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-hitlist-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
