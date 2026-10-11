#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase @end
@implementation FixtureReferenceUITests
- (void)testStandaloneProtocolsAndCopyLists {
    self.continueAfterFailure = NO;
    XCUIApplication *app = [[XCUIApplication alloc] init]; [app launch];
    NSPredicate *done = [NSPredicate predicateWithFormat:@"label == %@", @"PROTOCOL_OK"];
    [self expectationForPredicate:done evaluatedWithObject:app.staticTexts[@"protocol.status"] handler:nil];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = @"D1-protocol-ok"; shot.lifetime = XCTAttachmentLifetimeKeepAlways; [self addAttachment:shot];
}
@end
