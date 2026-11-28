import XCTest

final class FixtureReferenceUITests: XCTestCase {
    func testLaunchesTumblr() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "Tumblr must reach the foreground")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-tumblr-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
