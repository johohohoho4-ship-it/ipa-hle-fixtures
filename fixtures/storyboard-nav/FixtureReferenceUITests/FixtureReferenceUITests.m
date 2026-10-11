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
- (void)testShowSeguePushesAndPopReturns {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    XCTAssertTrue([app.navigationBars[@"Root"] waitForExistenceWithTimeout:15]);
    [self shot:app name:@"1-root"];
    [app.buttons[@"nav.show"] tap];
    XCTAssertTrue([app.navigationBars[@"Detail"] waitForExistenceWithTimeout:5]);
    XCTAssertEqualObjects(app.staticTexts[@"nav.detail"].label, @"Detail (from root)");
    [self shot:app name:@"2-detail"];
    [app.buttons[@"nav.pop"] tap];
    XCTAssertTrue([app.navigationBars[@"Root"] waitForExistenceWithTimeout:5]);
    [app.buttons[@"nav.go"] tap];
    XCTAssertTrue([app.navigationBars[@"Detail"] waitForExistenceWithTimeout:5]);
    [app.navigationBars[@"Detail"].buttons.firstMatch tap];
    XCTAssertTrue([app.navigationBars[@"Root"] waitForExistenceWithTimeout:5]);
    [self shot:app name:@"3-back"];
}
@end
