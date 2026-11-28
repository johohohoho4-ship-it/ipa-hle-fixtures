import XCTest

final class FixtureReferenceUITests: XCTestCase {
    func testLaunchesBrowser() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "Browser must reach the foreground")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-browser-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
