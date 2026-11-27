#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)waitForLabel:(XCUIElement *)element toBeginWith:(NSString *)prefix {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label BEGINSWITH %@", prefix];
    XCTNSPredicateExpectation *expectation =
        [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:element];
    XCTAssertEqual([XCTWaiter waitForExpectations:@[expectation] timeout:5.0],
                   XCTWaiterResultCompleted, @"%@ did not begin with %@", element, prefix);
}

- (void)testTraitCallbacksAndDynamicProviderColors {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *title = app.staticTexts[@"tcb.title"];
    XCTAssertTrue([title waitForExistenceWithTimeout:15.0], @"The trait callbacks fixture must appear");

    XCUIElement *status = app.staticTexts[@"tcb.status"];
    [self waitForLabel:status toBeginWith:@"Style: Light (cb="];

    XCUIElement *toggle = app.buttons[@"tcb.toggle"];
    XCTAssertTrue(toggle.isHittable);

    [toggle tap];
    [self waitForLabel:status toBeginWith:@"Style: Dark (cb="];
    XCTAttachment *darkShot = [XCTAttachment attachmentWithScreenshot:[app screenshot]];
    darkShot.name = @"trait-callbacks-dark";
    darkShot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:darkShot];

    [toggle tap];
    [self waitForLabel:status toBeginWith:@"Style: Light (cb="];
    XCTAttachment *lightShot = [XCTAttachment attachmentWithScreenshot:[app screenshot]];
    lightShot.name = @"trait-callbacks-light";
    lightShot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:lightShot];
}

@end
