#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase
@end
@implementation FixtureReferenceUITests
- (void)setUp { [super setUp]; self.continueAfterFailure = NO; }
- (void)testImagesAreLoadedAndDrawn {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    XCTAssertTrue([app.otherElements[@"images.root"] waitForExistenceWithTimeout:15]);
    XCTAssertTrue([app.images[@"images.fill"] exists]);
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = @"images";
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
}
@end
