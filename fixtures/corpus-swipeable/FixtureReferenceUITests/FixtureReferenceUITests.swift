import XCTest

/// Corpus smoke test for SwipeableCollectionViewCell-Example (MIT, amerhukic).
/// It measures the first screen of 19 collection-view items, swiping the first
/// cell left and deleting it through the revealed delete button.
///
/// A collection view only realises the visible cells, so the item count is read
/// from an accessibility-only probe (`items.count`) that the app fills from its
/// data source; every interaction itself is addressed by label or identifier.
final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testSwipeToDeleteFlow() {
        let app = XCUIApplication()
        app.launch()

        let collectionView = app.collectionViews["items.collection"]
        XCTAssertTrue(collectionView.waitForExistence(timeout: 20),
                      "Die Sammlung erschien nicht")

        let firstItem = app.staticTexts["Item 1"]
        XCTAssertTrue(firstItem.waitForExistence(timeout: 10),
                      "Der erste Eintrag fehlt")

        let countProbe = app.staticTexts["items.count"]
        XCTAssertTrue(countProbe.waitForExistence(timeout: 10),
                      "Der Zähler fehlt")
        XCTAssertEqual(countProbe.label, "19",
                       "Die Sammlung startet nicht mit 19 Einträgen")

        let start = XCTAttachment(screenshot: app.screenshot())
        start.name = "SwipeableCorpus-start"
        start.lifetime = .keepAlways
        add(start)

        let firstCell = collectionView.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 10), "Die erste Zelle fehlt")
        firstCell.swipeLeft()

        let deleteButton = firstCell.buttons["cell.delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 10),
                      "Der Lösch-Knopf wurde nicht aufgedeckt")
        expectation(for: NSPredicate(format: "isHittable == true"),
                    evaluatedWith: deleteButton)
        waitForExpectations(timeout: 10)
        deleteButton.tap()

        let swiped = XCTAttachment(screenshot: app.screenshot())
        swiped.name = "SwipeableCorpus-swiped"
        swiped.lifetime = .keepAlways
        add(swiped)

        expectation(for: NSPredicate(format: "exists == false"),
                    evaluatedWith: firstItem)
        waitForExpectations(timeout: 10)

        expectation(for: NSPredicate(format: "label == '18'"),
                    evaluatedWith: countProbe)
        waitForExpectations(timeout: 10)
        XCTAssertTrue(app.staticTexts["Item 2"].waitForExistence(timeout: 10),
                      "Der zweite Eintrag fehlt nach dem Löschen")

        let deleted = XCTAttachment(screenshot: app.screenshot())
        deleted.name = "SwipeableCorpus-after-delete"
        deleted.lifetime = .keepAlways
        add(deleted)
    }
}
