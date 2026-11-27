import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testDeterministicHashingValuesSetDictionaryOrder() {
        let app = XCUIApplication()
        // The measured seed model: execution seed (0, 0); a hash table's seed is its scale.
        app.launchEnvironment["SWIFT_DETERMINISTIC_HASHING"] = "1"
        app.launch()

        let status = app.staticTexts["deterministic-hashing.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20))
        expectation(for: NSPredicate(format: "label == %@", "DH_DONE"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "swift-deterministic-hashing-complete"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
