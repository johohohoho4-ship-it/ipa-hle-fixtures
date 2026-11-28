import XCTest

final class FixtureReferenceUITests: XCTestCase {
    func testLaunchesToDoList() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "ToDoList must reach the foreground")

        XCTAssertTrue(app.tables.firstMatch.waitForExistence(timeout: 10),
                      "The task table must be visible")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-todolistuikit-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
