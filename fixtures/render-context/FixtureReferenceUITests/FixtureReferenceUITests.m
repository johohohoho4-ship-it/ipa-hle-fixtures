#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase
@end
@implementation FixtureReferenceUITests
- (void)setUp { [super setUp]; self.continueAfterFailure = NO; }
- (void)testRenderContextFixtureFinishes {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label == %@", @"RC_DONE"];
    [self expectationForPredicate:predicate evaluatedWithObject:app.staticTexts[@"rc.status"] handler:nil];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = @"Render-context";
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
}
@end
