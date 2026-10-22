#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests
- (void)waitForState:(NSString *)state inApp:(XCUIApplication *)app {
    XCUIElement *label = app.staticTexts[@"ws.state"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label == %@", state];
    XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:label];
    XCTAssertEqual([XCTWaiter waitForExpectations:@[expectation] timeout:10.0], XCTWaiterResultCompleted);
}
- (void)capture:(NSString *)name {
    XCTAttachment *attachment = [XCTAttachment attachmentWithScreenshot:XCUIScreen.mainScreen.screenshot];
    attachment.name = name;
    attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:attachment];
}
- (void)testSceneGeometry {
    self.continueAfterFailure = NO;
    XCUIDevice.sharedDevice.orientation = UIDeviceOrientationPortrait;
    XCUIApplication *app = [XCUIApplication new];
    [app launch];
    @try {
        [self waitForState:@"portrait-ready" inApp:app];
        [self capture:@"ws-portrait"];
        XCUIDevice.sharedDevice.orientation = UIDeviceOrientationLandscapeLeft;
        [self waitForState:@"landscape-ready" inApp:app];
        [self capture:@"ws-landscape"];
        XCUIDevice.sharedDevice.orientation = UIDeviceOrientationPortrait;
        [self waitForState:@"restored-ready" inApp:app];
        [self capture:@"ws-restored"];
    } @finally {
        XCUIDevice.sharedDevice.orientation = UIDeviceOrientationPortrait;
    }
}
@end
