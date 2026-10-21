import XCTest

final class CorpusUITests: XCTestCase {
    func testLaunchesAndDraws() {
        let app = XCUIApplication()
        app.launch()

        let canvas = app.otherElements["drawing.canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 15), "The drawing canvas must appear")

        let start = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.25))
        let end = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.75))
        start.press(forDuration: 0.2, thenDragTo: end)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "corpus-drawing-after-drag"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
