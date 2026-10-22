#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase
@end
@implementation FixtureReferenceUITests
- (void)setUp { [super setUp]; self.continueAfterFailure = NO; }
- (void)testOldGuideArchiveProfile {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    XCTAssertTrue([app.staticTexts[@"ga.status"] waitForExistenceWithTimeout:15]);
    NSPredicate *done = [NSPredicate predicateWithFormat:@"label == %@", @"GA_DONE"];
    [self expectationForPredicate:done evaluatedWithObject:app.staticTexts[@"ga.status"] handler:nil];
    [self waitForExpectationsWithTimeout:20 handler:nil];
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = @"guide-archive-plain";
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
}
@end
