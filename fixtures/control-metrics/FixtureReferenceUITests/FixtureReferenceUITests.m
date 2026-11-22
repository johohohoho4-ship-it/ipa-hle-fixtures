#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

// One launch: main.m truncates tmp/ipa-hle-console.log on every start, so a
// second test method would leave only the last run in the native console.
// The measurement itself happens synchronously in viewDidLoad; this test only
// proves that the layout completed and attaches the rendered screen.
- (void)testControlMetricsInOneRun {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    XCTAssertTrue([app.staticTexts[@"cm.status"] waitForExistenceWithTimeout:15]);

    NSPredicate *done = [NSPredicate predicateWithFormat:@"label == %@", @"CM_DONE"];
    XCTestExpectation *expectation = [self expectationForPredicate:done
                                                evaluatedWithObject:app.staticTexts[@"cm.status"]
                                                            handler:nil];
    expectation.expectationDescription = @"cm.status == CM_DONE";
    [self waitForExpectationsWithTimeout:15 handler:nil];

    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = @"control-metrics";
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
}

@end
