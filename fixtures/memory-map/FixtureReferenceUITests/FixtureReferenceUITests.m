#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase
@end
@implementation FixtureReferenceUITests
- (void)testSharedMappingsAndLargeAllocation {
    self.continueAfterFailure = NO;
    XCUIApplication *app = [[XCUIApplication alloc] init]; [app launch];
    NSPredicate *done = [NSPredicate predicateWithFormat:@"label == %@", @"MEMORY_OK"];
    [self expectationForPredicate:done evaluatedWithObject:app.staticTexts[@"memory.status"] handler:nil];
    [self waitForExpectationsWithTimeout:20 handler:nil];
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = @"C5-memory-ok"; shot.lifetime = XCTAttachmentLifetimeKeepAlways; [self addAttachment:shot];
}
@end
