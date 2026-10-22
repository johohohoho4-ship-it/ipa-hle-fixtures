import XCTest

final class GitHubFollowersUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSearchScreenEmptyUsernameAlertAndTabs() throws {
        let app = XCUIApplication()
        app.launch()

        let field = app.textFields["Enter a user name"]
        XCTAssertTrue(field.waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["Get Followers"].exists)

        // Empty username: the app validates locally and shows an alert, no network.
        app.buttons["Get Followers"].tap()
        let alert = app.alerts["Error"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(alert.staticTexts["The username is not valid. Please enter a valid one so we know who you are looking for."].exists)
        alert.buttons["OK"].tap()
        XCTAssertFalse(alert.exists)

        // The favourites tab is empty on a fresh container.
        app.tabBars.buttons.element(boundBy: 1).tap()
        let empty = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "No favourites")).firstMatch
        XCTAssertTrue(empty.waitForExistence(timeout: 5))

        app.tabBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(field.waitForExistence(timeout: 5))
    }
}
