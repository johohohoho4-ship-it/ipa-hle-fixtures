#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)shot:(XCUIApplication *)app name:(NSString *)name {
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = name;
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
}

- (void)testControlsAndSegments {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    XCTAssertTrue([app.staticTexts[@"f12.status"] waitForExistenceWithTimeout:15]);
    [self shot:app name:@"1-start"];

    XCUIElement *toggle = app.switches.firstMatch;
    XCTAssertTrue([toggle waitForExistenceWithTimeout:10]);
    [toggle tap];
    XCUIElement *label = app.staticTexts[@"f12.status"];
    NSPredicate *off = [NSPredicate predicateWithFormat:@"label == %@", @"SWITCH=0"];
    [self waitForExpectations:@[[self expectationForPredicate:off evaluatedWithObject:label handler:nil]] timeout:20];
    [self shot:app name:@"2-switch-off"];

    [app.segmentedControls.buttons[@"C"] tap];
    NSPredicate *segment = [NSPredicate predicateWithFormat:@"label == %@", @"SEGMENT=2"];
    [self waitForExpectations:@[[self expectationForPredicate:segment evaluatedWithObject:label handler:nil]] timeout:20];
    [self shot:app name:@"3-segment-c"];
}

@end
