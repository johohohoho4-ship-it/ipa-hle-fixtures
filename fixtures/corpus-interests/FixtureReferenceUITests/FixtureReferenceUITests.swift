import XCTest

final class FixtureReferenceUITests: XCTestCase {
    func testLaunchesInterests() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "Interests must reach the foreground")

        XCTAssertTrue(app.collectionViews.firstMatch.waitForExistence(timeout: 10),
                      "The interest collection view must be visible")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-interests-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
