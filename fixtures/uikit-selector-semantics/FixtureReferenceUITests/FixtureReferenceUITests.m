#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

// One launch: main.m truncates tmp/ipa-hle-console.log on every start, so a second
// test method would leave only the last run in the native console. The button runs
// both measurement blocks once; the status label turns DONE afterwards.
- (void)testSelectorSemanticsInOneRun {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *run = app.buttons[@"selm.run"];
    XCTAssertTrue([run waitForExistenceWithTimeout:15]);
    XCUIElement *status = app.staticTexts[@"selm.status"];
    XCTAssertTrue([status waitForExistenceWithTimeout:15]);

    [run tap];

    NSPredicate *done = [NSPredicate predicateWithFormat:@"label == %@", @"DONE"];
    XCTestExpectation *expectation = [self expectationForPredicate:done
                                                evaluatedWithObject:status
                                                            handler:nil];
    expectation.expectationDescription = @"selm.status == DONE";
    [self waitForExpectationsWithTimeout:15 handler:nil];

    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = @"uikit-selector-semantics";
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
}

@end
