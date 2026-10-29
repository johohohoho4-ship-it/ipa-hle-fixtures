import XCTest

final class FixtureReferenceUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // One launch, one console file: the app logs the frames and every state change.
    func testInputsReportStateAndFrames() {
        let app = XCUIApplication()
        app.launch()

        let status = app.staticTexts["inp.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 20), "The inputs fixture must appear")
        waitFor(label: "ready", on: status)
        attach(app, "swiftui-inputs-ready")

        let toggle = app.switches["inp.toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 10), "The Toggle must be queryable")
        toggle.tap()
        waitFor(label: "toggled", on: status)
        attach(app, "swiftui-inputs-toggle")

        let field = app.textFields["inp.text"]
        XCTAssertTrue(field.waitForExistence(timeout: 10), "The TextField must be queryable")
        field.tap()
        field.typeText("Mila")
        // Return dismisses the keyboard via @FocusState in the app; no coordinate tap.
        field.typeText("\n")
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 10),
                      "The keyboard must close after Return")
        waitFor(label: "typed:Mila", on: status)
        attach(app, "swiftui-inputs-text")

        let slider = app.sliders["inp.slider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 10), "The Slider must be queryable")
        slider.adjust(toNormalizedSliderPosition: 0.5)
        // The exact snapped value is printed by the app; wait for the status prefix only.
        waitForPrefix("slider:", on: status)
        attach(app, "swiftui-inputs-slider")

        let stepper = app.steppers["inp.stepper"].exists
            ? app.steppers["inp.stepper"]
            : app.steppers.firstMatch
        XCTAssertTrue(stepper.waitForExistence(timeout: 10), "The Stepper must be queryable")
        // SwiftUI's Stepper exposes its two inner buttons without identifiers; the
        // increment is found by its accessibility label, never by a coordinate.
        let incrementPredicate = NSPredicate(format: "label IN %@", ["Increment", "Erhöhen"])
        let increment = stepper.buttons.matching(incrementPredicate).firstMatch
        XCTAssertTrue(increment.waitForExistence(timeout: 10),
                      "The Stepper increment must exist:\n\(stepper.debugDescription)")
        increment.tap()
        waitFor(label: "stepper:1", on: status)
        increment.tap()
        waitFor(label: "stepper:2", on: status)
        attach(app, "swiftui-inputs-stepper")

        let segmented = app.segmentedControls["inp.picker"].exists
            ? app.segmentedControls["inp.picker"]
            : app.segmentedControls.firstMatch
        XCTAssertTrue(segmented.waitForExistence(timeout: 10), "The Picker must be queryable")
        let segment = segmented.buttons["Drei"]  // index 2 of Eins/Zwei/Drei
        XCTAssertTrue(segment.waitForExistence(timeout: 10), "The third segment must exist")
        segment.tap()
        waitFor(label: "picked:2", on: status)
        attach(app, "swiftui-inputs-picker")

        // The DatePicker stays untouched: opening the calendar needs a day cell tap
        // that is not addressable without guessing a coordinate. See the README.
        attach(app, "swiftui-inputs-final")
    }

    private func waitFor(label: String, on element: XCUIElement, timeout: TimeInterval = 20) {
        let predicateExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", label),
            object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [predicateExpectation], timeout: timeout), .completed,
                       "Expected status \(label), got \(element.label)")
    }

    private func waitForPrefix(_ prefix: String, on element: XCUIElement, timeout: TimeInterval = 20) {
        let predicateExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label BEGINSWITH %@", prefix),
            object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [predicateExpectation], timeout: timeout), .completed,
                       "Expected status prefix \(prefix), got \(element.label)")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
