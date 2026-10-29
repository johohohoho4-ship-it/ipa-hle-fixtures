#import <XCTest/XCTest.h>

/// D5: the fixture prints its collection results to stdout; the test proves the app
/// reaches the screen and captures it. The values are compared from the console log.
@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)testCollectionsScreenAppears {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCTAssertTrue([app.staticTexts[@"collections.title"] waitForExistenceWithTimeout:20],
                  @"Das Collections-Label erschien nicht");
    XCTAssertEqualObjects(app.staticTexts[@"collections.title"].label, @"Collections");

    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = @"CollectionsNative-start";
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
}

@end
