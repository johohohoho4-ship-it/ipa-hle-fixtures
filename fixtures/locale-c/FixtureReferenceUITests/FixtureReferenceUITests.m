#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)testLocaleCChecks {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *title = app.staticTexts[@"loc.title"];
    XCTAssertTrue([title waitForExistenceWithTimeout:15.0], @"The locale-c fixture must appear");

    XCUIElement *status = app.staticTexts[@"loc.status"];
    XCTAssertTrue([status waitForExistenceWithTimeout:5.0], @"The status label must appear");
    XCTAssertEqualObjects(status.label, @"Locale OK (8 checks)");

    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:[app screenshot]];
    shot.name = @"locale-c-cold-start";
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
}

@end
