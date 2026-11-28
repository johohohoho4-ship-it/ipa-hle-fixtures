import XCTest

final class FixtureReferenceUITests: XCTestCase {
    func testLaunchesAnimations() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "Animations must reach the foreground")

        XCTAssertTrue(app.tables.firstMatch.waitForExistence(timeout: 10),
                      "The animation list must be visible")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-animations-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
