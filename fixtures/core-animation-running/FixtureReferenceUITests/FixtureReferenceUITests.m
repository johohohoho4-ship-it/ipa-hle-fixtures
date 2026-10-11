#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase
@end
@implementation FixtureReferenceUITests
- (void)setUp { [super setUp]; self.continueAfterFailure = NO; }
- (void)expect:(XCUIApplication *)app label:(NSString *)label {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label == %@", label];
    [self expectationForPredicate:predicate evaluatedWithObject:app.staticTexts[@"ca.status"] handler:nil];
    [self waitForExpectationsWithTimeout:8 handler:nil];
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = label;
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
}
- (void)testRunningPauseResumeAndUnwatchedFrames {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    [self expect:app label:@"Paused"];
    [app.buttons[@"ca.step1"] tap];
    [self expect:app label:@"Finished"];
    [app.buttons[@"ca.step2"] tap];
    [self expect:app label:@"Removed"];
    [app.buttons[@"ca.step3"] tap];
    [self expect:app label:@"Unwatched finished"];
}
@end
