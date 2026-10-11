#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase
@end
@implementation FixtureReferenceUITests
- (void)setUp { [super setUp]; self.continueAfterFailure = NO; }
- (void)shot:(XCUIApplication *)app name:(NSString *)name {
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = name;
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
}
- (void)testThreeLevelsBackButtonAndPopToRoot {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    XCTAssertTrue([app.navigationBars[@"Root"] waitForExistenceWithTimeout:15]);
    XCTAssertTrue(app.staticTexts[@"nav.label"].exists);
    [self shot:app name:@"1-root"];
    [app.navigationBars.buttons[@"Add"] tap];
    XCTAssertEqualObjects(app.staticTexts[@"nav.label"].label, @"Added");
    [app.buttons[@"nav.push"] tap];
    XCTAssertTrue([app.navigationBars[@"Level 2"] waitForExistenceWithTimeout:5]);
    [self shot:app name:@"2-level2"];
    [app.buttons[@"nav.push"] tap];
    XCTAssertTrue([app.navigationBars[@"Level 3"] waitForExistenceWithTimeout:5]);
    [self shot:app name:@"3-level3"];
    [app.navigationBars[@"Level 3"].buttons[@"Back2"] tap];
    XCTAssertTrue([app.navigationBars[@"Level 2"] waitForExistenceWithTimeout:5]);
    [self shot:app name:@"4-level2-after-back"];
    [app.buttons[@"nav.push"] tap];
    XCTAssertTrue([app.navigationBars[@"Level 3"] waitForExistenceWithTimeout:5]);
    [app.buttons[@"nav.root"] tap];
    XCTAssertTrue([app.navigationBars[@"Root"] waitForExistenceWithTimeout:5]);
    [app.buttons[@"nav.push"] tap];
    XCTAssertTrue([app.navigationBars[@"Level 2"] waitForExistenceWithTimeout:5]);
    [app.buttons[@"nav.push"] tap];
    [app.buttons[@"nav.pop"] tap];
    XCTAssertTrue([app.navigationBars[@"Level 2"] waitForExistenceWithTimeout:5]);
    [self shot:app name:@"5-level2-after-pop"];
    [app.buttons[@"nav.push"] tap];
    XCTAssertTrue([app.navigationBars[@"Level 3"] waitForExistenceWithTimeout:5]);
    [app.buttons[@"nav.popto"] tap];
    XCTAssertTrue([app.navigationBars[@"Level 2"] waitForExistenceWithTimeout:5]);
    [app.buttons[@"nav.push"] tap];
    [app.buttons[@"nav.replace"] tap];
    XCTAssertTrue([app.navigationBars[@"Level 4"] waitForExistenceWithTimeout:5]);
    [self shot:app name:@"6-level4"];
    [app.buttons[@"nav.hide"] tap];
    XCTAssertFalse(app.navigationBars.count > 0);
    [self shot:app name:@"7-bar-hidden"];
    [app.buttons[@"nav.hide"] tap];
    XCTAssertTrue([app.navigationBars[@"Level 4"] waitForExistenceWithTimeout:5]);
    [app.navigationBars[@"Level 4"].buttons[@"Done"] tap];
    XCTAssertTrue([app.navigationBars[@"Root"] waitForExistenceWithTimeout:5]);
}
@end
