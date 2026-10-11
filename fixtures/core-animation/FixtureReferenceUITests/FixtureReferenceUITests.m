#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase
@end
@implementation FixtureReferenceUITests
- (void)setUp { [super setUp]; self.continueAfterFailure = NO; }
- (void)expect:(XCUIApplication *)app stage:(NSInteger)stage value:(NSString *)value {
    NSString *label = [NSString stringWithFormat:@"Sample %ld %@", (long)stage, value];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label == %@", label];
    [self expectationForPredicate:predicate evaluatedWithObject:app.staticTexts[@"ca.status"] handler:nil];
    [self waitForExpectationsWithTimeout:5 handler:nil];
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = [NSString stringWithFormat:@"ca-stage%ld", (long)stage];
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
}
- (void)testPausedOpacityCopiesAndPresentation {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    [self expect:app stage:0 value:@"0.200"];
    NSArray *values = @[@"0.400", @"0.600", @"1.000", @"0.800"];
    for (NSInteger stage=1; stage<=4; ++stage) {
        [app.buttons[[NSString stringWithFormat:@"ca.step%ld", (long)stage]] tap];
        [self expect:app stage:stage value:values[stage-1]];
    }
}
@end
