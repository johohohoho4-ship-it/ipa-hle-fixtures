import XCTest

final class FixtureReferenceUITests: XCTestCase {
    func testLaunchesQBChatModelView() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "QBChatModelViewCorpus must reach the foreground")
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 10),
                      "QBChatModelViewCorpus must show its chat list navigation bar")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-qbchat-modelview-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
