import XCTest

final class CorpusUITests: XCTestCase {
    func testLaunchesPong() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20), "Pong must reach the foreground")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-pong-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
