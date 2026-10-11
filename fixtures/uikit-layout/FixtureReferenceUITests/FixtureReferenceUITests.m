#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)testStackLayoutAndControlAction {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *title = app.staticTexts[@"layout.title"];
    XCTAssertTrue([title waitForExistenceWithTimeout:15.0], @"The layout screen must appear");
    XCTAssertEqualObjects(title.label, @"Layout Fixture");

    XCUIElement *count = app.staticTexts[@"layout.count"];
    XCTAssertTrue([count waitForExistenceWithTimeout:5.0]);
    XCTAssertEqualObjects(count.label, @"Anzahl: 0");

    XCUIElement *increment = app.buttons[@"layout.increment"];
    XCTAssertTrue([increment waitForExistenceWithTimeout:5.0]);
    [increment tap];
    [increment tap];
    XCTAssertEqualObjects(count.label, @"Anzahl: 2");

    XCTAttachment *screenshot = [XCTAttachment attachmentWithScreenshot:[app screenshot]];
    screenshot.name = @"uikit-layout-two-steps";
    screenshot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:screenshot];
}

@end
