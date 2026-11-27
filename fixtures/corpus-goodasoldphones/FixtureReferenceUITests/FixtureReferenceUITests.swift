import XCTest

final class FixtureReferenceUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testProductsToDetailFlow() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tables["gaop.products"].waitForExistence(timeout: 15))

        let firstProduct = app.staticTexts["1907 Wall Set"]
        XCTAssertTrue(firstProduct.waitForExistence(timeout: 10))
        attachScreenshot(name: "GoodAsOldPhonesCorpus-products", app: app)

        // Tap the first table row; the push segue opens the product detail scene.
        firstProduct.tap()

        let productName = app.staticTexts["gaop.product.name"]
        XCTAssertTrue(productName.waitForExistence(timeout: 10))
        XCTAssertEqual(productName.label, "1907 Wall Set")

        let addToCart = app.buttons["gaop.addtocart"]
        XCTAssertTrue(addToCart.waitForExistence(timeout: 5))
        addToCart.tap()

        attachScreenshot(name: "GoodAsOldPhonesCorpus-detail", app: app)
    }

    private func attachScreenshot(name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
