#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase
@end
@implementation FixtureReferenceUITests
- (void)testAutoresizingSamples {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    XCTAssertTrue([app.staticTexts[@"ar.done"] waitForExistenceWithTimeout:15]);
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = @"autoresizing-samples-complete";
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
}
@end
