import XCTest

final class FixtureReferenceUITests: XCTestCase {
    func testLaunchesFlickrSearch() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "FlickrSearch must reach the foreground")

        XCTAssertTrue(app.collectionViews.firstMatch.waitForExistence(timeout: 10),
                      "The photo collection view must be visible")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-flickrsearch-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
