import XCTest

final class FixtureReferenceUITests: XCTestCase {
    func testLaunchesClassicPhotos() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "ClassicPhotos must reach the foreground")

        XCTAssertTrue(app.tables.firstMatch.waitForExistence(timeout: 10),
                      "The photo table must be visible")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-classicphotos-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
