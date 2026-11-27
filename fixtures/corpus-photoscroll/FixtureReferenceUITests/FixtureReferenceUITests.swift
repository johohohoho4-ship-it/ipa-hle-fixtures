import XCTest

final class FixtureReferenceUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    func testPhotoGridToPageBrowser() {
        let app = XCUIApplication()
        app.launch()

        let collection = app.collectionViews["photoscroll.collection"]
        let identifiedCell = app.cells["photoscroll.cell"].firstMatch
        XCTAssertTrue(collection.waitForExistence(timeout: 15) || identifiedCell.exists,
                      "The photo grid did not appear")
        attachScreenshot(name: "PhotoScrollCorpus-grid", app: app)

        let firstCell: XCUIElement
        if identifiedCell.waitForExistence(timeout: 10) {
            firstCell = identifiedCell
        } else {
            firstCell = collection.cells.element(boundBy: 0)
        }
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        firstCell.tap()

        let comment = app.staticTexts["photoscroll.comment"]
        XCTAssertTrue(comment.waitForExistence(timeout: 15))
        XCTAssertTrue(app.scrollViews.firstMatch.exists)
        attachScreenshot(name: "PhotoScrollCorpus-photo", app: app)

        let page = app.otherElements["photoscroll.page"]
        if page.exists {
            page.swipeLeft()
            XCTAssertTrue(comment.waitForExistence(timeout: 5))
            XCTAssertTrue(page.waitForExistence(timeout: 5))
        } else {
            app.swipeLeft()
            XCTAssertTrue(comment.waitForExistence(timeout: 5))
        }
    }

    private func attachScreenshot(name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
