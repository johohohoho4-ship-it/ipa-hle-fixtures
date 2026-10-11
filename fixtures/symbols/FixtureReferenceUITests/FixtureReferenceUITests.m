#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)testStandInSymbolsAreVisible {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *title = app.staticTexts[@"symbols.title"];
    XCTAssertTrue([title waitForExistenceWithTimeout:15.0]);
    XCTAssertEqualObjects(title.label, @"Ersatzsymbole, nicht SF Symbols");
    XCTAssertTrue([app.staticTexts[@"star.fill"] waitForExistenceWithTimeout:5.0]);
    XCTAssertTrue(app.images[@"checkmark"].exists);

    XCTAttachment *screenshot = [XCTAttachment attachmentWithScreenshot:[app screenshot]];
    screenshot.name = @"symbols-ersatz";
    screenshot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:screenshot];
}

@end
