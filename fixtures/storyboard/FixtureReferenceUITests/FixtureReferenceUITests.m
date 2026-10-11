#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase
@end
@implementation FixtureReferenceUITests
- (void)setUp { [super setUp]; self.continueAfterFailure = NO; }
- (void)testStoryboardSegueAndReturn {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    XCTAssertTrue([app.staticTexts[@"sb.first"] waitForExistenceWithTimeout:15]);
    XCTAssertTrue(app.staticTexts[@"sb.card"].exists);
    [app.buttons[@"sb.tap"] tap];
    XCTAssertEqualObjects(app.staticTexts[@"sb.first"].label, @"Tapped");
    [app.buttons[@"sb.next"] tap];
    XCTAssertTrue([app.staticTexts[@"sb.second"] waitForExistenceWithTimeout:5]);
    XCTAssertTrue([app.staticTexts[@"Second scene (from first)"] exists]);
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = @"storyboard-second";
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
    [app.buttons[@"sb.back"] tap];
    XCTAssertTrue([app.staticTexts[@"sb.first"] waitForExistenceWithTimeout:5]);
    XCTAssertEqualObjects(app.staticTexts[@"sb.first"].label, @"Tapped");
    [app.buttons[@"sb.go"] tap];
    XCTAssertTrue([app.staticTexts[@"sb.second"] waitForExistenceWithTimeout:5]);
    [app.buttons[@"sb.back"] tap];
    XCTAssertTrue([app.staticTexts[@"sb.first"] waitForExistenceWithTimeout:5]);
}
@end
