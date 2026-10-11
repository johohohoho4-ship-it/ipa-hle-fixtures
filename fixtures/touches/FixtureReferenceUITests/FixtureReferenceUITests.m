#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase
@end
@implementation FixtureReferenceUITests
- (void)setUp { [super setUp]; self.continueAfterFailure = NO; }
- (void)expect:(XCUIApplication *)app label:(NSString *)label {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label == %@", label];
    [self expectationForPredicate:predicate evaluatedWithObject:app.staticTexts[@"touch.status"] handler:nil];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}
- (void)testViewCaptureAndForwarding {
    XCUIApplication *app = [[XCUIApplication alloc] init]; [app launch]; [self expect:app label:@"Ready"];
    XCUICoordinate *origin = [app coordinateWithNormalizedOffset:CGVectorMake(0,0)];
    XCUICoordinate *start = [origin coordinateWithOffset:CGVectorMake(100,170)];
    XCUICoordinate *end = [origin coordinateWithOffset:CGVectorMake(300,500)];
    [start pressForDuration:0.1 thenDragToCoordinate:end]; [self expect:app label:@"Done 1"];
    [start tap]; [self expect:app label:@"Done 2"];
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = @"Touch-capture-forwarding"; shot.lifetime = XCTAttachmentLifetimeKeepAlways; [self addAttachment:shot];
}
@end
