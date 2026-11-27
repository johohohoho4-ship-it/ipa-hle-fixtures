import XCTest

final class FixtureReferenceUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    func testTipCalculationFlow() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Enter bill total"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Select tip"].exists)
        attachScreenshot(name: "TipsyCorpus-start", app: app)

        let bill = app.textFields["tipsy.bill"]
        XCTAssertTrue(bill.waitForExistence(timeout: 5))
        bill.tap()
        bill.typeText("100")

        // Dismiss the decimal pad (no return key) through the view's tap gesture.
        app.staticTexts["Choose Split"].tap()

        app.buttons["tipsy.tip.10"].tap()
        app.buttons["Calculate"].tap()

        let amount = app.staticTexts["tipsy.result.amount"]
        XCTAssertTrue(amount.waitForExistence(timeout: 10))
        XCTAssertEqual(amount.label, "55.0")
        XCTAssertEqual(app.staticTexts["tipsy.result.summary"].label,
                       "Split between 2 people, with 10% tip.")
        attachScreenshot(name: "TipsyCorpus-result", app: app)
    }

    private func attachScreenshot(name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
