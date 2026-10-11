#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)testDispatchQueuesTimersGroupsAndOnce {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *title = app.staticTexts[@"dispatch.title"];
    XCTAssertTrue([title waitForExistenceWithTimeout:15.0], @"The dispatch fixture must appear");

    XCUIElement *status = app.staticTexts[@"dispatch.status"];
    XCTAssertTrue([status waitForExistenceWithTimeout:5.0]);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label == %@", @"DISPATCH_OK"];
    XCTestExpectation *expectation = [self expectationForPredicate:predicate evaluatedWithObject:status handler:nil];
    [self waitForExpectations:@[expectation] timeout:60.0];
    XCTAssertEqualObjects(status.label, @"DISPATCH_OK");

    XCTAttachment *screenshot = [XCTAttachment attachmentWithScreenshot:[app screenshot]];
    screenshot.name = @"dispatch-async-all-primitives-passed";
    screenshot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:screenshot];
}

@end