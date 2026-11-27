import XCTest

final class FixtureReferenceUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    func testShelfAndPassbookLayouts() {
        let app = XCUIApplication()
        app.launch()

        // Statisches Tabellenmenue aus dem Storyboard.
        let shelfEntry = app.staticTexts["Shelf Layout"]
        XCTAssertTrue(shelfEntry.waitForExistence(timeout: 30), "Menue 'Shelf Layout' nicht gefunden")
        attachScreenshot(named: "01-menu", app: app)

        shelfEntry.tap()

        // Entweder die Sektionsueberschrift des Buchregals oder die Collection View selbst.
        let shelfHeader = app.staticTexts["Section 0"]
        let shelfCollection = app.collectionViews["layouts.collection"]
        let shelfScreen = waitForAny([shelfHeader, shelfCollection], timeout: 30)
        XCTAssertNotNil(shelfScreen, "Buchregal-Ansicht erschien nicht (Navigationstitel: '\(app.navigationBars.firstMatch.identifier)')")
        XCTAssertTrue(app.navigationBars.firstMatch.exists, "Keine Navigationsleiste auf der Buchregal-Ansicht")
        attachScreenshot(named: "02-shelf", app: app)

        // Zurueck zum Menue.
        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 10), "Zurueck-Schaltflaeche fehlt")
        backButton.tap()

        let passbookEntry = app.staticTexts["Passbook Layout"]
        XCTAssertTrue(passbookEntry.waitForExistence(timeout: 10), "Menue 'Passbook Layout' nicht gefunden")
        passbookEntry.tap()

        // Entweder die erste Karte oder die Collection View selbst.
        let passbookCard = app.staticTexts["Card 0"]
        let passbookCollection = app.collectionViews["layouts.collection"]
        let passbookScreen = waitForAny([passbookCard, passbookCollection], timeout: 30)
        XCTAssertNotNil(passbookScreen, "Passbook-Ansicht erschien nicht (Navigationstitel: '\(app.navigationBars.firstMatch.identifier)')")
        attachScreenshot(named: "03-passbook", app: app)
    }

    /// Wartet, bis mindestens eines der Elemente existiert, und gibt es zurueck.
    private func waitForAny(_ elements: [XCUIElement], timeout: TimeInterval) -> XCUIElement? {
        let predicate = NSPredicate { _, _ in elements.contains(where: { $0.exists }) }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        guard XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed else {
            return nil
        }
        return elements.first(where: { $0.exists })
    }

    private func attachScreenshot(named name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
