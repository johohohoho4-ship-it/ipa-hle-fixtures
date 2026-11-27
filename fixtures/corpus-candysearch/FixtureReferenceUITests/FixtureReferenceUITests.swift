import XCTest

final class FixtureReferenceUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    func testCandySearchFlow() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Chocolate Bar"].waitForExistence(timeout: 20))
        attachScreenshot(name: "CandySearchCorpus-start", app: app)

        // The identifier "candy.search" sits on the UISearchBar; the inner
        // UISearchTextField does not always inherit it, so use the single
        // search field of the screen.
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 10))
        searchField.tap()
        searchField.typeText("lolli")

        XCTAssertTrue(app.staticTexts["Lollipop"].waitForExistence(timeout: 10))
        attachScreenshot(name: "CandySearchCorpus-filtered", app: app)

        // Tapping the only result pushes the detail scene on iPhone.
        app.staticTexts["Lollipop"].tap()
        let detail = app.staticTexts["candy.detail"]
        XCTAssertTrue(detail.waitForExistence(timeout: 10))
        XCTAssertEqual(detail.label, "Lollipop")
    }

    private func attachScreenshot(name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
