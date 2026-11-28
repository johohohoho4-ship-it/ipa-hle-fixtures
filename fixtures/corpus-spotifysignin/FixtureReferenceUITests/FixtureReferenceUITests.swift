import XCTest

final class FixtureReferenceUITests: XCTestCase {
    func testLaunchesSpotifySignIn() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "SpotifySignIn must reach the foreground")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-spotifysignin-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
