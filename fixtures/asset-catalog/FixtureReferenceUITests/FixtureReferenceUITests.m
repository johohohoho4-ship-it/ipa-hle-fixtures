#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)testAssetCatalogFixtureStarts {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *status = app.staticTexts[@"ac.status"];
    XCTAssertTrue([status waitForExistenceWithTimeout:20.0],
                  @"The asset-catalog fixture must reach the ready screen");
    XCTAssertEqualObjects(status.label, @"ready");

    XCTAttachment *screenshot = [XCTAttachment attachmentWithScreenshot:[app screenshot]];
    screenshot.name = @"asset-catalog-start";
    screenshot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:screenshot];
}

@end
