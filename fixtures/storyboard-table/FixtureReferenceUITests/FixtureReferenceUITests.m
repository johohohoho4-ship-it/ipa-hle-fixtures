#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase
@end
@implementation FixtureReferenceUITests
- (void)setUp { [super setUp]; self.continueAfterFailure = NO; }
- (void)expect:(XCUIApplication *)app label:(NSString *)label {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label == %@", label];
    [self expectationForPredicate:predicate evaluatedWithObject:app.staticTexts[label] handler:nil];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}
- (void)attach:(XCUIApplication *)app name:(NSString *)name {
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = name; shot.lifetime = XCTAttachmentLifetimeKeepAlways; [self addAttachment:shot];
}
- (void)testStoryboardTableRowsAndTap {
    XCUIApplication *app = [[XCUIApplication alloc] init]; [app launch];
    // Both prototype rows must be visible; their labels come from the table view cell, not from the scene.
    [self expect:app label:@"Row 1"];
    [self expect:app label:@"Row 2"];
    [self attach:app name:@"StoryboardTable-rows"];
    XCUIElement *cell = app.cells.staticTexts[@"Row 2"];
    XCTAssertTrue([cell waitForExistenceWithTimeout:10]);
    [cell tap];
    // didSelectRowAtIndexPath rewrites the detail label of the tapped cell.
    [self expect:app label:@"Selected 2"];
    [self attach:app name:@"StoryboardTable-tap-selected"];
}
@end
