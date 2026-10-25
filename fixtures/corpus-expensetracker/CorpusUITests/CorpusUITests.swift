import XCTest

final class CorpusUITests: XCTestCase {
    func testLaunchesWithBothTabs() {
        let app = XCUIApplication()
        app.launch()

        let dashboard = app.buttons["Dashboard"]
        XCTAssertTrue(dashboard.waitForExistence(timeout: 20), "The Dashboard tab must appear")

        let logs = app.buttons["Logs"]
        XCTAssertTrue(logs.exists, "The Logs tab must appear")
        logs.tap()

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-expensetracker-logs"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
