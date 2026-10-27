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
    // A real tap on the cell that shows "Row 1". Step 5 deleted the old row 2, so the visible
    // texts are "Row 0", "Row 1", "Row 3", ...; the first two rows are always on screen and the
    // label lookup avoids a coordinate guess.
    XCUIElement *cell = app.cells.staticTexts[@"Row 1"];
    XCTAssertTrue([cell waitForExistenceWithTimeout:5]);
    [cell tap];
    [self expect:app label:@"Selected 1"];
    [self attach:app name:@"Table-tap-selected"];
}
@end
