#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)testThreadLocalStorageAndJoin {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *title = app.staticTexts[@"pthread.title"];
    XCTAssertTrue([title waitForExistenceWithTimeout:15.0], @"The thread fixture must appear");

    XCUIElement *result = app.staticTexts[@"pthread.result"];
    XCTAssertTrue([result waitForExistenceWithTimeout:5.0]);
    XCTAssertEqualObjects(result.label, @"Noch nicht gestartet.");

    XCUIElement *runButton = app.buttons[@"pthread.run"];
    XCTAssertTrue([runButton waitForExistenceWithTimeout:5.0]);
    [runButton tap];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label == %@", @"PTHREAD_OK:17:23"];
    XCTestExpectation *expectation = [self expectationForPredicate:predicate evaluatedWithObject:result handler:nil];
    [self waitForExpectations:@[expectation] timeout:15.0];
    XCTAssertEqualObjects(result.label, @"PTHREAD_OK:17:23");

    XCTAttachment *screenshot = [XCTAttachment attachmentWithScreenshot:[app screenshot]];
    screenshot.name = @"pthread-two-workers-tls-join";
    screenshot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:screenshot];
}

@end