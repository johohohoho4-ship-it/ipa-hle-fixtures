#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase
@end
@implementation FixtureReferenceUITests
- (void)setUp { [super setUp]; self.continueAfterFailure = NO; }
- (void)expect:(XCUIApplication *)app label:(NSString *)label {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label == %@", label];
    [self expectationForPredicate:predicate evaluatedWithObject:app.staticTexts[@"table.status"] handler:nil];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}
- (void)attach:(XCUIApplication *)app name:(NSString *)name {
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = name; shot.lifetime = XCTAttachmentLifetimeKeepAlways; [self addAttachment:shot];
}
- (void)testTableLoadScrollSelectAndDelete {
    XCUIApplication *app = [[XCUIApplication alloc] init]; [app launch]; [self expect:app label:@"Ready"];
    for (NSInteger n = 1; n <= 5; n++) {
        [app.buttons[@"table.advance"] tap];
        [self expect:app label:[NSString stringWithFormat:@"Done %ld", (long)n]];
        [self attach:app name:[NSString stringWithFormat:@"Table-step-%ld", (long)n]];
    }
    // A real tap on the third visible row (frame y 100 + 28 header + 88 = row 2 after the deletion): the delegate answers.
    XCUICoordinate *origin = [app coordinateWithNormalizedOffset:CGVectorMake(0, 0)];
    [[origin coordinateWithOffset:CGVectorMake(120, 100 + 28 + 44 * 2 + 20)] tap];
    [self expect:app label:@"Selected 2"];
    [self attach:app name:@"Table-tap-selected"];
}
@end
