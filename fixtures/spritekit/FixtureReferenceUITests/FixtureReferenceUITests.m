#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)waitForStatus:(NSString *)text in:(XCUIApplication *)app {
    XCUIElement *status = app.staticTexts[@"sk.status"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label == %@", text];
    XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:status];
    XCTAssertEqual([XCTWaiter waitForExpectations:@[expectation] timeout:20.0], XCTWaiterResultCompleted);
}

- (void)testGameRunsAndReactsToTaps {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    [self waitForStatus:@"SK_READY" in:app];

    XCTAttachment *ready = [XCTAttachment attachmentWithScreenshot:[app screenshot]];
    ready.name = @"spritekit-ready";
    ready.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:ready];

    XCUICoordinate *origin = [app coordinateWithNormalizedOffset:CGVectorMake(0, 0)];
    [[origin coordinateWithOffset:CGVectorMake(195, 444)] tap];   // the box, scene point (195, 400)
    [self waitForStatus:@"SK_TAP 1" in:app];

    XCTAttachment *tapped = [XCTAttachment attachmentWithScreenshot:[app screenshot]];
    tapped.name = @"spritekit-tapped";
    tapped.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:tapped];
}

@end
