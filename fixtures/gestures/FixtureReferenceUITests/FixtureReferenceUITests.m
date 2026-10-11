#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase
@end
@implementation FixtureReferenceUITests
- (void)setUp { [super setUp]; self.continueAfterFailure = NO; }
- (void)expect:(XCUIApplication *)app label:(NSString *)label {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label == %@", label];
    [self expectationForPredicate:predicate evaluatedWithObject:app.staticTexts[@"tg.status"] handler:nil];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}
- (void)testTapRecognizerAcrossAncestorAndChild {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    [self expect:app label:@"Ready"];
    XCUICoordinate *origin = [app coordinateWithNormalizedOffset:CGVectorMake(0, 0)];
    [[origin coordinateWithOffset:CGVectorMake(220, 240)] tap];
    [self expect:app label:@"Idle 1"];
    [[origin coordinateWithOffset:CGVectorMake(100, 170)] tap];
    [self expect:app label:@"Idle 2"];
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = @"Tap-ancestor-child";
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
}
@end
