#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase
@end
@implementation FixtureReferenceUITests
- (void)setUp { [super setUp]; self.continueAfterFailure = NO; }
- (void)expectStatus:(XCUIApplication *)app predicate:(NSPredicate *)predicate {
    [self expectationForPredicate:predicate evaluatedWithObject:app.staticTexts[@"scn.status"] handler:nil];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}
- (void)expectStatus:(XCUIApplication *)app label:(NSString *)label {
    [self expectStatus:app predicate:[NSPredicate predicateWithFormat:@"label == %@", label]];
}
- (void)attach:(XCUIApplication *)app name:(NSString *)name {
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = name; shot.lifetime = XCTAttachmentLifetimeKeepAlways; [self addAttachment:shot];
}
- (void)testStoryboardScrollviewSwipeAndProgrammaticSteps {
    XCUIApplication *app = [[XCUIApplication alloc] init]; [app launch];
    // The label starts with "Ready" from the storyboard and only changes after measured input.
    [self expectStatus:app label:@"Ready"];
    XCUIElement *scroll = app.scrollViews[@"scn.scroll"];
    XCTAssertTrue([scroll waitForExistenceWithTimeout:10]);
    XCTAssertTrue(scroll.hittable);
    [self attach:app name:@"StoryboardScrollview-start"];
    // A real swipe on the storyboard scroll view must move the content offset. The app
    // reports the settled offset as "OFFSET <rounded y>"; zero would mean no movement.
    [scroll swipeUp];
    [self expectStatus:app predicate:[NSPredicate predicateWithFormat:
        @"label BEGINSWITH %@ AND label != %@", @"OFFSET ", @"OFFSET 0"]];
    [self attach:app name:@"StoryboardScrollview-offset"];
    // Step 1: setContentOffset:animated:NO, Step 2: setContentInset:, Step 3: reset.
    for (NSInteger n = 1; n <= 3; n++) {
        [app.buttons[@"scn.step"] tap];
        [self expectStatus:app label:[NSString stringWithFormat:@"PROG %ld", (long)n]];
        [self attach:app name:[NSString stringWithFormat:@"StoryboardScrollview-step-%ld", (long)n]];
    }
}
@end
