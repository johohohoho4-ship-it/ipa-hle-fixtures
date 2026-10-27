#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase @end
@implementation FixtureReferenceUITests
- (void)testStandaloneProtocolsAndCopyLists {
    self.continueAfterFailure = NO;
    XCUIApplication *app = [[XCUIApplication alloc] init]; [app launch];
    NSPredicate *done = [NSPredicate predicateWithFormat:@"label BEGINSWITH %@", @"PROTOCOL_"];
    [self expectationForPredicate:done evaluatedWithObject:app.staticTexts[@"protocol.status"] handler:nil];
    [self waitForExpectationsWithTimeout:15 handler:nil];
    NSString *status = app.staticTexts[@"protocol.status"].label;
    NSString *details = app.staticTexts[@"protocol.details"].label;
    XCTAttachment *report = [XCTAttachment attachmentWithString:[NSString stringWithFormat:@"status=%@ failed=%@", status, details]];
    report.name = @"D1-protocol-report";
    report.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:report];
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = @"D1-protocol-status";
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
    XCTAssertEqualObjects(status, @"PROTOCOL_OK", @"failed checks: %@", details);
}
@end
