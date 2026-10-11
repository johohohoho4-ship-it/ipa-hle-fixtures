#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase
@end
@implementation FixtureReferenceUITests
- (void)setUp { [super setUp]; self.continueAfterFailure = NO; }
- (void)expect:(XCUIApplication *)app label:(NSString *)label {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label == %@", label];
    [self expectationForPredicate:predicate evaluatedWithObject:app.staticTexts[@"pan.status"] handler:nil];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}
- (void)testPanCaptureTranslationAndReset {
    XCUIApplication *app = [[XCUIApplication alloc] init]; [app launch]; [self expect:app label:@"Ready"];
    XCUICoordinate *origin = [app coordinateWithNormalizedOffset:CGVectorMake(0,0)];
    XCUICoordinate *start = [origin coordinateWithOffset:CGVectorMake(100,170)];
    [start pressForDuration:0.1 thenDragToCoordinate:[origin coordinateWithOffset:CGVectorMake(300,500)]];
    [self expect:app label:@"Idle 1"];
    [start pressForDuration:0.1 thenDragToCoordinate:[origin coordinateWithOffset:CGVectorMake(160,260)]];
    [self expect:app label:@"Idle 2"];
    [start pressForDuration:0.1 thenDragToCoordinate:[origin coordinateWithOffset:CGVectorMake(115,185)]
        withVelocity:20.0 thenHoldForDuration:0.1];
    [self expect:app label:@"Idle 3"];
    [start pressForDuration:0.1 thenDragToCoordinate:[origin coordinateWithOffset:CGVectorMake(50,120)]];
    [self expect:app label:@"Idle 4"];
    [start pressForDuration:0.1 thenDragToCoordinate:[origin coordinateWithOffset:CGVectorMake(160,260)]];
    [self expect:app label:@"Idle 5"];
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = @"Pan-capture-translation"; shot.lifetime = XCTAttachmentLifetimeKeepAlways; [self addAttachment:shot];
}
@end
