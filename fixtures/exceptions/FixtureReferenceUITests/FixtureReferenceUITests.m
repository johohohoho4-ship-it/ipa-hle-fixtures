#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)testObjCAndCxxExceptionsAreCaught {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *title = app.staticTexts[@"exceptions.title"];
    XCTAssertTrue([title waitForExistenceWithTimeout:15.0], @"The exceptions fixture must appear");

    XCUIElement *status = app.staticTexts[@"exceptions.status"];
    XCTAssertTrue([status waitForExistenceWithTimeout:5.0]);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label == %@", @"EXCEPTIONS_OK"];
    XCTestExpectation *expectation = [self expectationForPredicate:predicate evaluatedWithObject:status handler:nil];
    [self waitForExpectations:@[expectation] timeout:60.0];
    XCTAssertEqualObjects(status.label, @"EXCEPTIONS_OK");

    XCTAttachment *screenshot = [XCTAttachment attachmentWithScreenshot:[app screenshot]];
    screenshot.name = @"exceptions-all-cases-passed";
    screenshot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:screenshot];
}

@end