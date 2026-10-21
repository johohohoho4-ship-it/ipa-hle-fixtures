import XCTest

final class CorpusUITests: XCTestCase {
    func testAddsATodo() {
        let app = XCUIApplication()
        app.launch()

        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 20), "The new-item field must appear")
        field.tap()
        field.typeText("Milk\n")

        XCTAssertTrue(app.staticTexts["Milk"].waitForExistence(timeout: 10), "The new todo must appear")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-simpletodo-after-add"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
