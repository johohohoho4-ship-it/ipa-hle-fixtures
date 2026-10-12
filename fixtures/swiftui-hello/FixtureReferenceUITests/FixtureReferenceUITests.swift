import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// Frames in points of the window, as the HLE layout must reproduce them.
    private func logFrame(_ element: XCUIElement, _ name: String) {
        let f = element.frame
        print("SWU_UI_FRAME \(name) x=\(f.origin.x) y=\(f.origin.y) w=\(f.size.width) h=\(f.size.height)")
    }

    func testHelloShowsStackedTexts() {
        let app = XCUIApplication()
        app.launch()

        let title = app.staticTexts["hello.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 15), "The SwiftUI hello view must appear")
        XCTAssertEqual(title.label, "Hello, SwiftUI")
        let subtitle = app.staticTexts["hello.subtitle"]
        XCTAssertTrue(subtitle.exists)
        XCTAssertEqual(subtitle.label, "IPA-HLE H1")
        XCTAssertLessThan(title.frame.maxY, subtitle.frame.minY, "VStack puts the title above the subtitle")
        logFrame(app.windows.firstMatch, "window")
        logFrame(title, "title")
        logFrame(subtitle, "subtitle")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "swiftui-hello"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
