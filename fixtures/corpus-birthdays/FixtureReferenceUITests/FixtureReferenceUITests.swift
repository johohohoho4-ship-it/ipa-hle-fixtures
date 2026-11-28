import XCTest

final class FixtureReferenceUITests: XCTestCase {
    func testLaunchesBirthdays() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "Birthdays must reach the foreground")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-birthdays-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
