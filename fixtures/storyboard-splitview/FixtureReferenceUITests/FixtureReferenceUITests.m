#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)expectStatus:(XCUIApplication *)app label:(NSString *)label {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label == %@", label];
    [self expectationForPredicate:predicate evaluatedWithObject:app.staticTexts[@"spv.status"] handler:nil];
    [self waitForExpectationsWithTimeout:20 handler:nil];
}

- (void)attach:(XCUIApplication *)app name:(NSString *)name {
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = name;
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
}

- (void)testSplitViewPortraitLandscapePortrait {
    XCUIDevice.sharedDevice.orientation = UIDeviceOrientationPortrait;
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    @try {
        XCTAssertTrue([app.staticTexts[@"spv.status"] waitForExistenceWithTimeout:20]);
        // The split controller sets READY from its own viewDidAppear after the initial layout.
        [self expectStatus:app label:@"READY"];
        [self attach:app name:@"StoryboardSplitview-portrait"];

        XCUIDevice.sharedDevice.orientation = UIDeviceOrientationLandscapeLeft;
        // LANDSCAPE is set from the rotation's transition completion, after the re-measured frames.
        [self expectStatus:app label:@"LANDSCAPE"];
        [self attach:app name:@"StoryboardSplitview-landscape"];

        XCUIDevice.sharedDevice.orientation = UIDeviceOrientationPortrait;
        [self expectStatus:app label:@"PORTRAIT"];
        [self attach:app name:@"StoryboardSplitview-restored"];
    } @finally {
        XCUIDevice.sharedDevice.orientation = UIDeviceOrientationPortrait;
    }
}

@end
