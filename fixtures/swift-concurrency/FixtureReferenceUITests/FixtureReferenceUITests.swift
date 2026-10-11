import XCTest
final class FixtureReferenceUITests: XCTestCase {
    override func setUp() { super.setUp(); continueAfterFailure = false }
    func testActorTasksAndMainActor() {
        let app = XCUIApplication(); app.launch()
        let status = app.staticTexts["concurrency.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 15))
        expectation(for: NSPredicate(format: "label == %@", "CONCURRENCY_OK"), evaluatedWith: status)
        waitForExpectations(timeout: 15)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "concurrency-complete"; shot.lifetime = .keepAlways; add(shot)
    }
}
