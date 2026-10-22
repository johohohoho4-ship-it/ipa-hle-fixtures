import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testSceneCoordinateSpaceAndRotation() {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["scene.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20))
        expectation(for: NSPredicate(format: "label == %@", "SG_READY"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        XCUIDevice.shared.orientation = .landscapeLeft
        expectation(for: NSPredicate(format: "label == %@", "SG_DONE"), evaluatedWith: status)
        waitForExpectations(timeout: 20)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "scene-geometry-landscape"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
