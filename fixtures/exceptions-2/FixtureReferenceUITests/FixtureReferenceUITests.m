#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)testCxxExceptionCasesFinish {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *title = app.staticTexts[@"ex2.title"];
    XCTAssertTrue([title waitForExistenceWithTimeout:15.0], @"The exceptions-2 fixture must appear");

    XCUIElement *status = app.staticTexts[@"ex2.status"];
    XCTAssertTrue([status waitForExistenceWithTimeout:5.0]);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label == %@", @"EX2_DONE"];
    XCTestExpectation *expectation = [self expectationForPredicate:predicate evaluatedWithObject:status handler:nil];
    [self waitForExpectations:@[expectation] timeout:60.0];

    XCTAttachment *screenshot = [XCTAttachment attachmentWithScreenshot:[app screenshot]];
    screenshot.name = @"exceptions-2-done";
    screenshot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:screenshot];
}

@end
