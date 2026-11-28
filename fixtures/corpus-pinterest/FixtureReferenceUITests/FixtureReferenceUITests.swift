import XCTest

final class FixtureReferenceUITests: XCTestCase {
    func testLaunchesPinterest() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "Pinterest must reach the foreground")

        XCTAssertTrue(app.collectionViews.firstMatch.waitForExistence(timeout: 10),
                      "The photo stream collection view must be visible")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-pinterest-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
