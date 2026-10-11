#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase
@end
@implementation FixtureReferenceUITests
- (void)setUp { [super setUp]; self.continueAfterFailure = NO; }
- (void)testContainmentAndModalReturn {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    XCTAssertTrue([app.staticTexts[@"vc.child"] waitForExistenceWithTimeout:15]);
    for (NSString *button in @[@"vc.fullscreen", @"vc.overlay", @"vc.automatic", @"vc.pagesheet", @"vc.formsheet", @"vc.popover"]) {
        [app.buttons[button] tap];
        XCTAssertTrue([app.staticTexts[@"vc.modal"] waitForExistenceWithTimeout:5]);
        XCTAttachment *presented = [XCTAttachment attachmentWithScreenshot:app.screenshot];
        presented.name = button;
        presented.lifetime = XCTAttachmentLifetimeKeepAlways;
        [self addAttachment:presented];
        [app.buttons[@"vc.dismiss"] tap];
        XCTAssertTrue([app.staticTexts[@"vc.child"] waitForExistenceWithTimeout:5]);
        XCTAssertFalse(app.staticTexts[@"vc.modal"].exists);
    }
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = @"view-controller-returned";
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
}
@end
