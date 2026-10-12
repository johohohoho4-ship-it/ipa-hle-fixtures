#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase
@end
@implementation FixtureReferenceUITests
- (void)testThreadLocalDestructorsFinishBeforeJoin {
    self.continueAfterFailure = NO;
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    XCUIElement *status = app.staticTexts[@"pthreadlifecycle.status"];
    XCTAssertTrue([status waitForExistenceWithTimeout:30.0]);
    XCTAssertEqualObjects(status.label, @"PTHREAD_LIFECYCLE_OK");
    XCTAttachment *image = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    image.name = @"pthread-lifecycle";
    image.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:image];
}
@end
