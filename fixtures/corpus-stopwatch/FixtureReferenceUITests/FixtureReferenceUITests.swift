import XCTest

final class FixtureReferenceUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    func testStopwatchStartLapStop() {
        let app = XCUIApplication()
        app.launch()

        let timerLabel = app.staticTexts["stopwatch.main"]
        XCTAssertTrue(timerLabel.waitForExistence(timeout: 15))
        XCTAssertEqual(timerLabel.label, "00:00:00")
        attachScreenshot(name: "StopwatchCorpus-start", app: app)

        let playButton = app.buttons["stopwatch.play"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 5))
        XCTAssertEqual(playButton.label, "Start")
        playButton.tap()

        // The timer label is driven by a 0.035 s repeating Timer.
        let timerChanged = expectation(for: NSPredicate(format: "label != %@", "00:00:00"),
                                       evaluatedWith: timerLabel)
        wait(for: [timerChanged], timeout: 5)

        let lapButton = app.buttons["stopwatch.lapreset"]
        XCTAssertTrue(lapButton.waitForExistence(timeout: 5))
        XCTAssertEqual(lapButton.label, "Lap")
        lapButton.tap()

        let lapsTable = app.tables["stopwatch.laps"]
        XCTAssertTrue(lapsTable.cells.firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Lap 1"].waitForExistence(timeout: 5))

        XCTAssertEqual(playButton.label, "Stop")
        playButton.tap()
        attachScreenshot(name: "StopwatchCorpus-stop", app: app)
    }

    private func attachScreenshot(name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
