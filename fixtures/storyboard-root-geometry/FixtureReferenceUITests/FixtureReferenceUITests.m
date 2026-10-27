#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp { [super setUp]; self.continueAfterFailure = NO; }

- (void)runMode:(NSString *)mode access:(NSString *)access {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    app.launchEnvironment = @{@"GEOM_MODE": mode, @"GEOM_ACCESS": access};
    [app launch];
    XCUIElement *status = app.staticTexts[@"geom.status"];
    XCTAssertTrue([status waitForExistenceWithTimeout:20]);
    NSPredicate *done = [NSPredicate predicateWithFormat:@"label == %@", @"GEOM_DONE"];
    XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:done object:status];
    XCTAssertEqual([XCTWaiter waitForExpectations:@[expectation] timeout:20], XCTWaiterResultCompleted);
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = [NSString stringWithFormat:@"root-geometry-%@-%@", mode, access];
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
}

- (void)testPlainLazy { [self runMode:@"plain" access:@"lazy"]; }
- (void)testPlainEager { [self runMode:@"plain" access:@"eager"]; }
- (void)testNavLazy { [self runMode:@"nav" access:@"lazy"]; }
- (void)testNavEager { [self runMode:@"nav" access:@"eager"]; }

@end
