//
//  CleanStoreUITests.swift
//  CleanStoreUITests
//
//  Created by Raymond Law on 2/12/19.
//  Copyright © 2019 Clean Swift LLC. All rights reserved.
//

import XCTest

class CleanStoreUITests: XCTestCase
{
  override func setUp()
  {
    continueAfterFailure = false
    XCUIApplication().launch()
  }

  func testListOrdersAppears()
  {
    let app = XCUIApplication()
    let navigationBar = app.navigationBars["List Orders"]
    XCTAssertTrue(navigationBar.waitForExistence(timeout: 20), "The List Orders screen must appear")

    let addButton = navigationBar.buttons["Add"]
    XCTAssertTrue(addButton.exists, "The add button must be in the navigation bar")

    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "corpus-cleanstore-list-orders"
    screenshot.lifetime = .keepAlways
    add(screenshot)
  }
}
