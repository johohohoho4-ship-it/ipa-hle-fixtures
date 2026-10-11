#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase
@end
@implementation FixtureReferenceUITests
- (void)setUp { [super setUp]; self.continueAfterFailure = NO; }
- (void)expect:(XCUIApplication *)app label:(NSString *)label {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label == %@", label];
    [self expectationForPredicate:predicate evaluatedWithObject:app.staticTexts[@"scroll.status"] handler:nil];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}
- (void)testScrollGeometryAndDelegate {
    XCUIApplication *app = [[XCUIApplication alloc] init]; [app launch]; [self expect:app label:@"Ready"];
    for (NSInteger n=1;n<=4;n++) {
        [app.buttons[@"scroll.advance"] tap]; [self expect:app label:[NSString stringWithFormat:@"Done %ld",n]];
        XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
        shot.name = [NSString stringWithFormat:@"Scroll-step-%ld",n]; shot.lifetime = XCTAttachmentLifetimeKeepAlways; [self addAttachment:shot];
    }
    [app.buttons[@"scroll.advance"] tap]; [self expect:app label:@"Done 5"];
    XCUICoordinate *origin = [app coordinateWithNormalizedOffset:CGVectorMake(0,0)];
    XCUICoordinate *start = [origin coordinateWithOffset:CGVectorMake(100,250)];
    [start pressForDuration:0.1 thenDragToCoordinate:[origin coordinateWithOffset:CGVectorMake(100,140)]
        withVelocity:120.0 thenHoldForDuration:0.4];
    [self expect:app label:@"Drag Idle"];
    XCTAttachment *drag = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    drag.name = @"Scroll-drag-idle"; drag.lifetime = XCTAttachmentLifetimeKeepAlways; [self addAttachment:drag];
}
@end
