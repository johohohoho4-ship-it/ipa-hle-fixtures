import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func waitUntilGone(_ element: XCUIElement) {
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: element)
        waitForExpectations(timeout: 20)
    }

    /// The navigation bar as the test runner sees it (`xcodebuild-test.log`), and a screenshot.
    private func report(_ app: XCUIApplication, _ name: String) {
        let bar = app.navigationBars.element(boundBy: 0)
        print("NAVUI \(name) bar identifier=\(bar.identifier) frame=\(bar.frame)")
        for index in 0..<bar.buttons.count {
            let button = bar.buttons.element(boundBy: index)
            print("NAVUI \(name) bar.button.\(index) label=\(button.label) frame=\(button.frame)")
        }
        for index in 0..<bar.staticTexts.count {
            let text = bar.staticTexts.element(boundBy: index)
            print("NAVUI \(name) bar.text.\(index) label=\(text.label) frame=\(text.frame)")
        }
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "swiftui-navigation-\(name)"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    private func tapBack(_ app: XCUIApplication) {
        let back = app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0)
        XCTAssertTrue(back.waitForExistence(timeout: 10))
        back.tap()
    }

    func testRealTapsPushAndPop() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["nav.root"].waitForExistence(timeout: 20))
        sleep(1)
        report(app, "root")

        // NavigationLink(destination:), then the back button.
        let linkA = app.buttons["nav.link.a"]
        XCTAssertTrue(linkA.waitForExistence(timeout: 10))
        linkA.tap()
        XCTAssertTrue(app.staticTexts["nav.a"].waitForExistence(timeout: 10))
        sleep(1)
        report(app, "a")
        tapBack(app)
        waitUntilGone(app.staticTexts["nav.a"])
        XCTAssertTrue(app.staticTexts["nav.root"].waitForExistence(timeout: 10))
        sleep(1)

        // NavigationLink(value:) twice deep through navigationDestination(for:), then back twice.
        let link2 = app.buttons["nav.link.2"]
        XCTAssertTrue(link2.waitForExistence(timeout: 10))
        link2.tap()
        XCTAssertTrue(app.staticTexts["nav.number.2"].waitForExistence(timeout: 10))
        sleep(1)
        report(app, "number.2")
        let link3 = app.buttons["nav.link.3"]
        XCTAssertTrue(link3.waitForExistence(timeout: 10))
        link3.tap()
        XCTAssertTrue(app.staticTexts["nav.number.3"].waitForExistence(timeout: 10))
        sleep(1)
        report(app, "number.3")
        tapBack(app)
        waitUntilGone(app.staticTexts["nav.number.3"])
        sleep(1)
        tapBack(app)
        waitUntilGone(app.staticTexts["nav.number.2"])
        XCTAssertTrue(app.staticTexts["nav.root"].waitForExistence(timeout: 10))
        sleep(1)
        report(app, "root.after")
    }
}
