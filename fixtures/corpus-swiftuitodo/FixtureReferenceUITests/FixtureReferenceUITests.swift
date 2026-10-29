import XCTest

/// Corpus smoke test for SwiftUITodo (MIT, devxoul/SwiftUITodo).
/// It measures the first screen, creating a task through the list's text field,
/// toggling it done, the edit mode and persistence across a relaunch.
final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testTaskListFlow() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Tasks 👀"].waitForExistence(timeout: 20),
                      "Die Aufgabenliste erschien nicht")
        XCTAssertTrue(app.buttons["Read SwiftUI Documentation 📚"].exists)
        XCTAssertTrue(app.buttons["Watch WWDC19 Keynote 🎉"].exists)

        let start = XCTAttachment(screenshot: app.screenshot())
        start.name = "SwiftUITodo-start"
        start.lifetime = .keepAlways
        add(start)

        let field = app.textFields["task.new"]
        XCTAssertTrue(field.waitForExistence(timeout: 10), "Das Eingabefeld fehlt")
        field.tap()
        field.typeText("Buy milk")
        field.typeText("\n")

        let created = app.buttons["Buy milk"]
        XCTAssertTrue(created.waitForExistence(timeout: 10), "Die neue Aufgabe fehlt")

        created.tap()
        let done = app.descendants(matching: .any).matching(identifier: "task.done").firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 10), "Die Aufgabe wurde nicht als erledigt markiert")

        let afterCreate = XCTAttachment(screenshot: app.screenshot())
        afterCreate.name = "SwiftUITodo-after-create"
        afterCreate.lifetime = .keepAlways
        add(afterCreate)

        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["Buy milk"].waitForExistence(timeout: 20),
                      "Die Aufgabe überlebte den Neustart nicht")

        app.buttons["task.edit"].tap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 10),
                      "Der Bearbeitungsmodus wurde nicht eingeschaltet")
        let edit = XCTAttachment(screenshot: app.screenshot())
        edit.name = "SwiftUITodo-edit-mode"
        edit.lifetime = .keepAlways
        add(edit)
        app.buttons["Done"].tap()
    }
}
