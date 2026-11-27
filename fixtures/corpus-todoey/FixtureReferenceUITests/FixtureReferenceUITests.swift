import XCTest

/// Corpus-Referenztest für TodoeyCorpus (MIT, rchauhan9/Todoey).
/// Deckt nur den lokalen Ablauf ab: Hinzufügen über den Alert, Eintrag in der
/// Liste sehen, Zeile antippen. Kein Netz, keine Koordinaten, keine Wartezeiten.
final class FixtureReferenceUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testAddItemFlow() {
        let app = XCUIApplication()
        app.launch()

        let navigationBar = app.navigationBars["Todoey"]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 20),
                      "Die Navigationsleiste mit dem Titel Todoey erschien nicht")

        let addButton = navigationBar.buttons["todoey.add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 10),
                      "Der Hinzufügen-Button wurde nicht gefunden")
        attachScreenshot(name: "TodoeyCorpus-start", app: app)

        addButton.tap()

        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 10), "Der Eingabedialog erschien nicht")

        let textField = alert.textFields.firstMatch
        XCTAssertTrue(textField.waitForExistence(timeout: 5), "Das Textfeld im Dialog fehlt")
        XCTAssertEqual(textField.placeholderValue, "Create new item.")
        textField.tap()
        textField.typeText("Milk")

        alert.buttons["Add item."].tap()

        let list = app.tables["todoey.list"]
        XCTAssertTrue(list.waitForExistence(timeout: 10), "Die Aufgabenliste fehlt")

        let item = list.staticTexts["Milk"].firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 10), "Der Eintrag Milk erschien nicht")
        attachScreenshot(name: "TodoeyCorpus-after-add", app: app)

        item.tap()
        XCTAssertTrue(item.exists, "Der Eintrag Milk verschwand nach dem Antippen")
    }

    private func attachScreenshot(name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
