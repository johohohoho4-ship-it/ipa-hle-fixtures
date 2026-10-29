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

    // Second section (SBTX_*): prototype cell with outlets on an object outside the cell nib.
    // The launch argument makes the same tap on "Row 2" open the second scene, so one launch
    // prints the SBT_ section (including SBT_TAP) first and the SBTX_ section after it.
    [app terminate];
    app.launchArguments = @[@"-SBTXScene", @"YES"];
    [app launch];
    XCUIElement *secondRunCell = app.cells.staticTexts[@"Row 2"];
    XCTAssertTrue([secondRunCell waitForExistenceWithTimeout:10]);
    [secondRunCell tap];
    XCUIElement *externalRow = app.cells.staticTexts[@"SBTX Row 1"];
    XCTAssertTrue([externalRow waitForExistenceWithTimeout:10]);
    [self attach:app name:@"StoryboardTable-external-rows"];
    [externalRow tap];
    // The cell sends the callback through its storyboard outlet; only that call installs the
    // SBTX_DONE status label.
    [self expect:app label:@"SBTX_DONE"];
    [self attach:app name:@"StoryboardTable-external-done"];
}
@end
