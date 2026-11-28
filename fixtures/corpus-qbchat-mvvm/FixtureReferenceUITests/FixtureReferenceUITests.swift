import XCTest

final class FixtureReferenceUITests: XCTestCase {
    func testLaunchesQBChatMVVM() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "QBChatMVVMCorpus must reach the foreground")
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 10),
                      "QBChatMVVMCorpus must show its chat list navigation bar")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-qbchat-mvvm-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
