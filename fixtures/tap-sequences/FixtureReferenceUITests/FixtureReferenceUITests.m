#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (NSString *)statusWithSingle:(NSInteger)single
                        double:(NSInteger)doubleCount
                      deferred:(NSInteger)deferred
                       twoTaps:(NSInteger)twoTaps {
    return [NSString stringWithFormat:@"single=%ld double=%ld deferred=%ld twotaps=%ld",
            (long)single, (long)doubleCount, (long)deferred, (long)twoTaps];
}

- (void)expectStatus:(NSString *)text
               inApp:(XCUIApplication *)app
             timeout:(NSTimeInterval)timeout {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label == %@", text];
    XCTestExpectation *expectation = [self expectationForPredicate:predicate
                                                evaluatedWithObject:app.staticTexts[@"tap.status"]
                                                            handler:nil];
    expectation.expectationDescription = [NSString stringWithFormat:@"tap.status == %@", text];
    [self waitForExpectationsWithTimeout:timeout handler:nil];
}

- (void)attach:(XCUIApplication *)app name:(NSString *)name {
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = name;
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
}

// One launch for all four scenarios. main.m truncates tmp/ipa-hle-console.log
// on every launch, so separate test methods would leave only the last test in
// the native console reference. Counter expectations are cumulative:
//   start      single=0 double=0 deferred=0 twotaps=0
//   (a) single single=1 double=0 deferred=0 twotaps=0
//   (b) double single=1 double=1 deferred=0 twotaps=0
//   (c) defer  single=1 double=1 deferred=1 twotaps=0
//   (d) twotaps unchanged, then control tap on single -> single=2
- (void)testTapSequencesInOneRun {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    XCTAssertTrue([app.staticTexts[@"tap.status"] waitForExistenceWithTimeout:15]);
    [self expectStatus:[self statusWithSingle:0 double:0 deferred:0 twoTaps:0] inApp:app timeout:15];

    // (a) One tap on its own surface fires exactly the single-tap recognizer.
    XCUIElement *singleSurface = app.otherElements[@"surface.single"];
    XCTAssertTrue([singleSurface waitForExistenceWithTimeout:5]);
    [singleSurface tap];
    [self expectStatus:[self statusWithSingle:1 double:0 deferred:0 twoTaps:0] inApp:app timeout:5];

    // (b) Two quick taps fire the double-tap recognizer exactly once; the
    // require-to-fail single recognizer must not fire as well.
    XCUIElement *doubleSurface = app.otherElements[@"surface.double"];
    XCTAssertTrue([doubleSurface waitForExistenceWithTimeout:5]);
    [doubleSurface doubleTap];
    [self expectStatus:[self statusWithSingle:1 double:1 deferred:0 twoTaps:0] inApp:app timeout:5];
    [self attach:app name:@"tap-single-and-double"];

    // (c) One tap on the require-to-fail surface: the double recognizer stays
    // at zero and the deferred single recognizer fires after the double tap
    // failed.
    [doubleSurface tap];
    [self expectStatus:[self statusWithSingle:1 double:1 deferred:1 twoTaps:0] inApp:app timeout:5];
    XCTAssertEqualObjects(app.staticTexts[@"tap.status"].label,
                          [self statusWithSingle:1 double:1 deferred:1 twoTaps:0],
                          @"the double counter must remain one after the deferred single tap");
    [self attach:app name:@"tap-deferred-single"];

    // (d) A single tap on the double-tap surface without require-to-fail fires
    // no recognizer at all. The short inverted expectation leaves the app idle,
    // so the control tap below can follow immediately.
    XCUIElement *twoTapsSurface = app.otherElements[@"surface.twotaps"];
    XCTAssertTrue([twoTapsSurface waitForExistenceWithTimeout:5]);
    [twoTapsSurface tap];

    NSString *baseline = [self statusWithSingle:1 double:1 deferred:1 twoTaps:0];
    NSPredicate *changed = [NSPredicate predicateWithFormat:@"label != %@", baseline];
    XCTestExpectation *unchanged = [self expectationForPredicate:changed
                                             evaluatedWithObject:app.staticTexts[@"tap.status"]
                                                         handler:nil];
    unchanged.inverted = YES;
    unchanged.expectationDescription = @"no tap counter changes after one tap on twotaps";
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    XCTAssertEqualObjects(app.staticTexts[@"tap.status"].label, baseline,
                          @"a single tap must not satisfy the two-tap recognizer");

    // Control tap: proves the app is still live and that only the single
    // counter advances.
    [singleSurface tap];
    [self expectStatus:[self statusWithSingle:2 double:1 deferred:1 twoTaps:0] inApp:app timeout:5];
    [self attach:app name:@"tap-twotaps-and-control"];
}

@end
