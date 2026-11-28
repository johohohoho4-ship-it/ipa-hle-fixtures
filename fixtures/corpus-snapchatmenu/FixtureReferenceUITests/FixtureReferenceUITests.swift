import XCTest

final class FixtureReferenceUITests: XCTestCase {
    func testLaunchesSnapchatMenu() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "SnapchatMenu must reach the foreground")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-snapchatmenu-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
