#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase
@end
@implementation FixtureReferenceUITests
- (void)setUp { [super setUp]; self.continueAfterFailure = NO; }
- (void)expect:(XCUIApplication *)app label:(NSString *)label {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label == %@", label];
    [self expectationForPredicate:predicate evaluatedWithObject:app.staticTexts[@"collection.status"] handler:nil];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}
- (void)attach:(XCUIApplication *)app name:(NSString *)name {
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = name; shot.lifetime = XCTAttachmentLifetimeKeepAlways; [self addAttachment:shot];
}
- (void)testCollectionLoadScrollSelectAndLayout {
    XCUIApplication *app = [[XCUIApplication alloc] init]; [app launch]; [self expect:app label:@"Ready"];
    for (NSInteger n = 1; n <= 5; n++) {
        [app.buttons[@"collection.advance"] tap];
        [self expect:app label:[NSString stringWithFormat:@"Done %ld", (long)n]];
        [self attach:app name:[NSString stringWithFormat:@"Collection-step-%ld", (long)n]];
    }
    // A real tap on the first item (collection frame at 20,100; after step 5 the items are 70 x 40 at x 15, y 10).
    XCUICoordinate *origin = [app coordinateWithNormalizedOffset:CGVectorMake(0, 0)];
    [[origin coordinateWithOffset:CGVectorMake(20 + 15 + 30, 100 + 10 + 20)] tap];
    [self expect:app label:@"Selected 0.0"];
    [self attach:app name:@"Collection-tap-selected"];
}
@end
