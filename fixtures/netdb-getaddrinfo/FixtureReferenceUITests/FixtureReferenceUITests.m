#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)testNetdbGetaddrinfoChecks {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *title = app.staticTexts[@"gai.title"];
    XCTAssertTrue([title waitForExistenceWithTimeout:15.0], @"The netdb-getaddrinfo fixture must appear");

    XCUIElement *status = app.staticTexts[@"gai.status"];
    XCTAssertTrue([status waitForExistenceWithTimeout:5.0], @"The status label must appear");
    XCTAssertEqualObjects(status.label, @"Netdb OK (10 checks)");

    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:[app screenshot]];
    shot.name = @"netdb-getaddrinfo-cold-start";
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
}

@end
