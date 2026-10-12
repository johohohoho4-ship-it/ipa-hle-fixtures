#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)testTextLayoutIsVisible {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *status = app.staticTexts[@"text.status"];
    XCTAssertTrue([status waitForExistenceWithTimeout:15.0]);
    XCTAssertEqualObjects(status.label, @"TEXT_DONE");
    XCTAssertTrue(app.staticTexts[@"text.paragraph"].exists);

    XCTAttachment *screenshot = [XCTAttachment attachmentWithScreenshot:[app screenshot]];
    screenshot.name = @"text-layout";
    screenshot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:screenshot];
}

// Runs last (alphabetical order), so its app console is the one the workflow keeps: the reference
// lines of the first screen plus the SF Pro calibration (TEXT_CHARS for all weights, TEXT_TRACK,
// TEXT_KERN), which only this launch argument asks for.
- (void)testZCalibration {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    app.launchArguments = @[@"-ipahle-calibrate-sf"];
    [app launch];
    XCTAssertTrue([app.staticTexts[@"text.status"] waitForExistenceWithTimeout:15.0]);
    XCTAssertTrue([app.staticTexts[@"text.calibrated"] waitForExistenceWithTimeout:900.0]);
}

@end
