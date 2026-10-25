import XCTest

final class CorpusUITests: XCTestCase {
    func testLegacyGuideArchiveProfile() {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["ga.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 15), "The measurement label must appear")

        let done = NSPredicate(format: "label == %@", "GA_DONE")
        expectation(for: done, evaluatedWith: status, handler: nil)
        waitForExpectations(timeout: 20, handler: nil)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "guide-archive-after-measurement"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
