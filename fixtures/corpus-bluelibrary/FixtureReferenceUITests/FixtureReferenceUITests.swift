import XCTest

final class FixtureReferenceUITests: XCTestCase {
    func testLaunchesBlueLibrary() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "BlueLibrary must reach the foreground")

        XCTAssertTrue(app.tables.firstMatch.waitForExistence(timeout: 10),
                      "The album table must be visible")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-bluelibrary-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
