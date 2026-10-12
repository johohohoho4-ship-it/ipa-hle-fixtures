#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase
@end
@implementation FixtureReferenceUITests
- (void)setUp { [super setUp]; self.continueAfterFailure = NO; }
- (void)testStoryboardControls {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    XCTAssertTrue([app.otherElements[@"sbctl.tap"] waitForExistenceWithTimeout:15]);
    [app.switches[@"sbctl.switch"] tap];                     // valueChanged -> toggled:
    [app.otherElements[@"sbctl.tap"] doubleTap];             // the double tap recognizer -> tapped:
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = @"storyboard-controls";
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
}
@end
