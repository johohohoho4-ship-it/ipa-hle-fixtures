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

    private func screenshot(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "swiftui-presentation-\(name)"
        shot.lifetime = .keepAlways
        add(shot)
    }

    /// The navigation bar as the test runner sees it (`xcodebuild-test.log`), and a screenshot.
    private func reportBar(_ app: XCUIApplication, _ name: String) {
        let bar = app.navigationBars.element(boundBy: 0)
        print("PRSUI \(name) bar identifier=\(bar.identifier) frame=\(bar.frame)")
        for index in 0..<bar.buttons.count {
            let button = bar.buttons.element(boundBy: index)
            print("PRSUI \(name) bar.button.\(index) label=\(button.label) id=\(button.identifier) frame=\(button.frame)")
        }
        for index in 0..<bar.staticTexts.count {
            let text = bar.staticTexts.element(boundBy: index)
            print("PRSUI \(name) bar.text.\(index) label=\(text.label) frame=\(text.frame)")
        }
        screenshot(app, name)
    }

    private func reportElement(_ name: String, _ key: String, _ element: XCUIElement) {
        print("PRSUI \(name) \(key) label=\(element.label) frame=\(element.frame)")
    }

    /// The alert: its frame, its texts and its buttons in order.
    private func reportAlert(_ app: XCUIApplication, _ name: String) -> XCUIElement {
        let alert = app.alerts.element(boundBy: 0)
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        sleep(1)
        reportElement(name, "alert", alert)
        for index in 0..<alert.staticTexts.count {
            reportElement(name, "alert.text.\(index)", alert.staticTexts.element(boundBy: index))
        }
        for index in 0..<alert.buttons.count {
            reportElement(name, "alert.button.\(index)", alert.buttons.element(boundBy: index))
        }
        screenshot(app, name)
        return alert
    }

    private func tap(_ app: XCUIApplication, _ identifier: String) {
        let button = app.buttons[identifier]
        XCTAssertTrue(button.waitForExistence(timeout: 10), identifier)
        button.tap()
    }

    private func waitFor(_ app: XCUIApplication, _ identifier: String) {
        XCTAssertTrue(app.staticTexts[identifier].waitForExistence(timeout: 10), identifier)
        sleep(1)
    }

    func testRealTapsPathToolbarSheetAndAlert() {
        let app = XCUIApplication()
        app.launch()

        waitFor(app, "prs.root")
        reportBar(app, "root")

        // The toolbar's trailing button appends to the bound path; a value link appends once more.
        tap(app, "prs.add")
        waitFor(app, "prs.number.1")
        reportBar(app, "number.1")
        tap(app, "prs.link.2")
        waitFor(app, "prs.number.2")
        reportBar(app, "number.2")

        // The pushed screen's toolbar button empties the path: back to the root in one step.
        tap(app, "prs.pop")
        waitUntilGone(app.staticTexts["prs.number.2"])
        waitFor(app, "prs.root")
        reportBar(app, "root.pop")

        // A value link on the root appends to the path; the back button removes it again.
        tap(app, "prs.link.1")
        waitFor(app, "prs.number.1")
        let back = app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0)
        XCTAssertTrue(back.waitForExistence(timeout: 10))
        back.tap()
        waitUntilGone(app.staticTexts["prs.number.1"])
        waitFor(app, "prs.root")

        // The leading toolbar button shows the sheet; its button closes it through the binding.
        tap(app, "prs.sheet.open")
        waitFor(app, "prs.sheet")
        reportElement("sheet", "sheet.text", app.staticTexts["prs.sheet"])
        reportElement("sheet", "sheet.close", app.buttons["prs.sheet.close"])
        screenshot(app, "sheet")
        tap(app, "prs.sheet.close")
        waitUntilGone(app.staticTexts["prs.sheet"])
        sleep(1)

        // The alert twice: once the destructive button, once the cancel button.
        tap(app, "prs.alert")
        let alert = reportAlert(app, "alert")
        alert.buttons["Delete"].tap()
        waitUntilGone(alert)
        sleep(1)
        tap(app, "prs.alert")
        let again = reportAlert(app, "alert.again")
        again.buttons["Cancel"].tap()
        waitUntilGone(again)
        sleep(1)
        reportBar(app, "root.after")
    }
}
