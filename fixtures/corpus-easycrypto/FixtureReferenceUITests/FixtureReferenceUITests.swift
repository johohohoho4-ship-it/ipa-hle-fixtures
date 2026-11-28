import XCTest

final class FixtureReferenceUITests: XCTestCase {
    func testLaunchesEasyCrypto() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "EasyCrypto must reach the foreground")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-easycrypto-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
