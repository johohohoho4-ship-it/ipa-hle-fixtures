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

@end
