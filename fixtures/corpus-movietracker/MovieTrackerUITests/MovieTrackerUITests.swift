import XCTest

/// Corpus smoke test for the MovieTracker app (MIT, dmytrozykov/movietracker).
/// It only measures what works without network and without a TMDB key: the tab bar with
/// both screens and the switch between them. The list content itself is not asserted.
final class MovieTrackerUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testTabBarShowsBothScreens() {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 20), "Navigationsleiste der App erschien nicht")
        XCTAssertGreaterThanOrEqual(tabBar.buttons.count, 2, "Die App hat weniger als zwei Tabs")

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "MovieTracker-start"
        shot.lifetime = .keepAlways
        add(shot)

        let second = tabBar.buttons.element(boundBy: 1)
        second.tap()
        XCTAssertTrue(second.isSelected, "Der zweite Tab wurde nicht ausgewählt")

        let after = XCTAttachment(screenshot: app.screenshot())
        after.name = "MovieTracker-second-tab"
        after.lifetime = .keepAlways
        add(after)
    }
}
