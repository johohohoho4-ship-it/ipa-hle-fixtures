import XCTest

final class FixtureReferenceUITests: XCTestCase {
    func testLaunchesQBChatRedux() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "QBChatReduxCorpus must reach the foreground")
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 10),
                      "QBChatReduxCorpus must show its chat list navigation bar")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-qbchat-redux-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
