import XCTest

final class FixtureReferenceUITests: XCTestCase {
    func testLaunchesTodoTDD() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "TodoTDD must reach the foreground")

        XCTAssertTrue(app.tables.firstMatch.waitForExistence(timeout: 10),
                      "The item list table must be visible")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-todotdd-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
