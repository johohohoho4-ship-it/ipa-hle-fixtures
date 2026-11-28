import XCTest

final class FixtureReferenceUITests: XCTestCase {
    func testLaunchesArtistry() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "Artistry must reach the foreground")

        XCTAssertTrue(app.tables.firstMatch.waitForExistence(timeout: 10),
                      "The artist list table must be visible")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-artistry-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
