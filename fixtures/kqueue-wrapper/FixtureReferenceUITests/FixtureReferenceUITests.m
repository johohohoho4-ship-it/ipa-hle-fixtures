#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)testKqueueWrapperChecks {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *title = app.staticTexts[@"kq.title"];
    XCTAssertTrue([title waitForExistenceWithTimeout:15.0], @"The kqueue-wrapper fixture must appear");

    XCUIElement *status = app.staticTexts[@"kq.status"];
    XCTAssertTrue([status waitForExistenceWithTimeout:5.0], @"The status label must appear");
    XCTAssertEqualObjects(status.label, @"Kqueue OK (8 checks)");

    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:[app screenshot]];
    shot.name = @"kqueue-wrapper-cold-start";
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
}

@end
