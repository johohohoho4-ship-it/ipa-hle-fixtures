import XCTest

final class FixtureReferenceUITests: XCTestCase {
    func testLaunchesScale() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "Scale must reach the foreground")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-scale-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
