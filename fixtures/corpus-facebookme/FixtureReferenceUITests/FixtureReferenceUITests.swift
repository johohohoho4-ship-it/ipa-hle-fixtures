import XCTest

final class FixtureReferenceUITests: XCTestCase {
    func testLaunchesFacebookMe() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "FacebookMe must reach the foreground")

        XCTAssertTrue(app.tables.firstMatch.waitForExistence(timeout: 10),
                      "The profile table must be visible")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-facebookme-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
