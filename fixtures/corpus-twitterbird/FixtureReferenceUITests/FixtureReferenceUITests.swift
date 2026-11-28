import XCTest

final class FixtureReferenceUITests: XCTestCase {
    func testLaunchesTwitterBird() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "TwitterBird must reach the foreground")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-twitterbird-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
