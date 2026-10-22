#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)testSynchronisationStress {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *title = app.staticTexts[@"sync.title"];
    XCTAssertTrue([title waitForExistenceWithTimeout:15.0], @"The sync stress fixture must appear");

    XCUIElement *result = app.staticTexts[@"sync.result"];
    XCTAssertTrue([result waitForExistenceWithTimeout:5.0]);
    XCTAssertEqualObjects(result.label, @"Noch nicht gestartet.");

    XCUIElement *runButton = app.buttons[@"sync.run"];
    XCTAssertTrue([runButton waitForExistenceWithTimeout:5.0]);
    [runButton tap];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label == %@", @"SYNC_OK:8000:125250"];
    XCTestExpectation *expectation = [self expectationForPredicate:predicate evaluatedWithObject:result handler:nil];
    [self waitForExpectations:@[expectation] timeout:30.0];
    XCTAssertEqualObjects(result.label, @"SYNC_OK:8000:125250");

    XCTAttachment *screenshot = [XCTAttachment attachmentWithScreenshot:[app screenshot]];
    screenshot.name = @"sync-stress-result";
    screenshot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:screenshot];
}

@end
