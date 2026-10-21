#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase
@end
@implementation FixtureReferenceUITests
- (void)setUp { [super setUp]; self.continueAfterFailure = NO; }
- (void)testLayoutGuidesAndNavigationItems {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    XCTAssertTrue([app.staticTexts[@"lg.root"] waitForExistenceWithTimeout:15]);

    // Plain controller presented outside a navigation controller.
    [app.buttons[@"lg.plain"] tap];
    XCTAssertTrue([app.staticTexts[@"lg.plain.label"] waitForExistenceWithTimeout:5]);
    [app.buttons[@"lg.plain.close"] tap];
    XCTAssertTrue([app.staticTexts[@"lg.root"] waitForExistenceWithTimeout:5]);

    // NIB-installed bar items: system Add on the left, titled item on the right
    // (disabled in the NIB, enabled by the controller before this tap).
    [app.buttons[@"lg.add"] tap];
    XCTAssertEqualObjects(app.staticTexts[@"lg.state"].label, @"Add tapped");
    [app.buttons[@"lg.right"] tap];
    XCTAssertEqualObjects(app.staticTexts[@"lg.state"].label, @"Right tapped");

    [app.buttons[@"nav.show"] tap];
    XCTAssertTrue([app.staticTexts[@"nav.detail"] waitForExistenceWithTimeout:5]);
    XCTAssertTrue([app.staticTexts[@"Detail (from root)"] exists]);
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = @"layout-guides-detail";
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
    [app.buttons[@"nav.pop"] tap];
    XCTAssertTrue([app.staticTexts[@"lg.root"] waitForExistenceWithTimeout:5]);

    [app.buttons[@"nav.go"] tap];
    XCTAssertTrue([app.staticTexts[@"nav.detail"] waitForExistenceWithTimeout:5]);
    [app.buttons[@"nav.pop"] tap];
    XCTAssertTrue([app.staticTexts[@"lg.root"] waitForExistenceWithTimeout:5]);
}
@end
