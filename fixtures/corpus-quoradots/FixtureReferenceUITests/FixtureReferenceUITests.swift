import XCTest

final class FixtureReferenceUITests: XCTestCase {
    func testLaunchesQuoraDots() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "QuoraDots must reach the foreground")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-quoradots-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
