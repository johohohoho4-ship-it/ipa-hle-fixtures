#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)testUIKitPropertyGetters {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *button = app.buttons[@"props.run"];
    XCTAssertTrue([button waitForExistenceWithTimeout:10]);

    XCUIElement *status = app.staticTexts[@"props.status"];
    XCTAssertTrue([status waitForExistenceWithTimeout:10]);

    [button tap];

    NSPredicate *done = [NSPredicate predicateWithFormat:@"label == %@", @"DONE"];
    [self expectationForPredicate:done evaluatedWithObject:status handler:nil];
    [self waitForExpectationsWithTimeout:20 handler:nil];

    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = @"UIKitProperties-DONE";
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
}

@end
