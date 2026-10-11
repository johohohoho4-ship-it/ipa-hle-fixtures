#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
- (void)launchProfile:(NSString *)profile inApp:(XCUIApplication *)app;
- (XCUIElement *)profileItem:(NSUInteger)index inApp:(XCUIApplication *)app;
- (void)waitForProfileItemsInApp:(XCUIApplication *)app;
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)launchProfile:(NSString *)profile inApp:(XCUIApplication *)app {
    app.launchArguments = @[[NSString stringWithFormat:@"--stack-profile=%@", profile]];
    [app launch];
}

- (XCUIElement *)profileItem:(NSUInteger)index inApp:(XCUIApplication *)app {
    return app.staticTexts[[NSString stringWithFormat:@"profile.item%lu", (unsigned long)index]];
}

- (void)waitForProfileItemsInApp:(XCUIApplication *)app {
    for (NSUInteger index = 0; index < 3; index++) {
        XCTAssertTrue([[self profileItem:index inApp:app] waitForExistenceWithTimeout:10.0],
                      @"Profile item %lu did not appear", (unsigned long)index);
    }
}

- (void)testStackLayoutAndControlAction {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *title = app.staticTexts[@"layout.title"];
    XCTAssertTrue([title waitForExistenceWithTimeout:15.0], @"The layout screen must appear");
    XCTAssertEqualObjects(title.label, @"Layout Fixture");

    XCUIElement *description = app.staticTexts[@"layout.description"];
    XCUIElement *hidden = app.staticTexts[@"layout.hidden"];
    XCTAssertTrue([description waitForExistenceWithTimeout:5.0]);
    XCTAssertFalse(hidden.exists, @"A hidden arranged view must not remain an accessibility element");
    XCTAssertEqualWithAccuracy(description.frame.origin.y - CGRectGetMaxY(title.frame), 20.0, 2.0,
                                @"The hidden arranged view must not leave a spacing slot");

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

- (void)testStackDistributionSpacingHiddenViewsAndBaselines {
    XCUIApplication *app = [[XCUIApplication alloc] init];

    [self launchProfile:@"fill-equally-horizontal" inApp:app];
    XCUIElement *first = [self profileItem:0 inApp:app];
    XCUIElement *second = [self profileItem:1 inApp:app];
    XCUIElement *third = [self profileItem:2 inApp:app];
    [self waitForProfileItemsInApp:app];
    XCTAssertEqualWithAccuracy(first.frame.size.width, second.frame.size.width, 1.0);
    XCTAssertEqualWithAccuracy(second.frame.size.width, third.frame.size.width, 1.0);
    [app terminate];

    [self launchProfile:@"fill-proportionally-vertical" inApp:app];
    first = [self profileItem:0 inApp:app];
    second = [self profileItem:1 inApp:app];
    third = [self profileItem:2 inApp:app];
    [self waitForProfileItemsInApp:app];
    XCTAssertLessThan(first.frame.size.height, second.frame.size.height);
    XCTAssertLessThan(second.frame.size.height, third.frame.size.height);
    [app terminate];

    [self launchProfile:@"equal-spacing-vertical" inApp:app];
    first = [self profileItem:0 inApp:app];
    second = [self profileItem:1 inApp:app];
    third = [self profileItem:2 inApp:app];
    [self waitForProfileItemsInApp:app];
    XCTAssertEqualWithAccuracy(second.frame.origin.y - CGRectGetMaxY(first.frame),
                               third.frame.origin.y - CGRectGetMaxY(second.frame), 1.0);
    [app terminate];

    [self launchProfile:@"equal-centering-horizontal" inApp:app];
    first = [self profileItem:0 inApp:app];
    second = [self profileItem:1 inApp:app];
    third = [self profileItem:2 inApp:app];
    [self waitForProfileItemsInApp:app];
    CGFloat firstCenterGap = CGRectGetMidX(second.frame) - CGRectGetMidX(first.frame);
    CGFloat secondCenterGap = CGRectGetMidX(third.frame) - CGRectGetMidX(second.frame);
    XCTAssertEqualWithAccuracy(firstCenterGap, secondCenterGap, 1.0);
    [app terminate];

    [self launchProfile:@"equal-centering-single-horizontal" inApp:app];
    XCUIElement *only = [self profileItem:0 inApp:app];
    XCTAssertTrue([only waitForExistenceWithTimeout:10.0]);
    CGRect windowFrame = app.windows.firstMatch.frame;
    XCTAssertEqualWithAccuracy(only.frame.origin.x, windowFrame.origin.x + 20.0, 1.0);
    XCTAssertEqualWithAccuracy(only.frame.size.width, windowFrame.size.width - 40.0, 1.0);
    [app terminate];

    [self launchProfile:@"hidden-horizontal" inApp:app];
    first = [self profileItem:0 inApp:app];
    second = [self profileItem:2 inApp:app];
    XCTAssertTrue([first waitForExistenceWithTimeout:10.0]);
    XCTAssertTrue([second waitForExistenceWithTimeout:10.0]);
    XCTAssertFalse([self profileItem:1 inApp:app].exists);
    XCTAssertEqualWithAccuracy(second.frame.origin.x - CGRectGetMaxX(first.frame), 8.0, 1.0);
    [app terminate];

    [self launchProfile:@"negative-spacing-horizontal" inApp:app];
    first = [self profileItem:0 inApp:app];
    second = [self profileItem:1 inApp:app];
    XCTAssertTrue([first waitForExistenceWithTimeout:10.0]);
    XCTAssertTrue([second waitForExistenceWithTimeout:10.0]);
    XCTAssertLessThan(second.frame.origin.x, CGRectGetMaxX(first.frame),
                      @"Negative spacing permits adjacent arranged views to overlap");
    [app terminate];

    NSArray<NSString *> *baselineProfiles = @[@"first-baseline-horizontal", @"last-baseline-horizontal"];
    for (NSString *profile in baselineProfiles) {
        [self launchProfile:profile inApp:app];
        first = [self profileItem:0 inApp:app];
        second = [self profileItem:1 inApp:app];
        third = [self profileItem:2 inApp:app];
        [self waitForProfileItemsInApp:app];
        CGFloat firstSize = 12.0, secondSize = 24.0, thirdSize = 36.0;
        CGFloat firstBaseline, secondBaseline, thirdBaseline;
        if ([profile isEqualToString:@"first-baseline-horizontal"]) {
            firstBaseline = first.frame.origin.y + firstSize * (1950.0 / 2048.0);
            secondBaseline = second.frame.origin.y + secondSize * (1950.0 / 2048.0);
            thirdBaseline = third.frame.origin.y + thirdSize * (1950.0 / 2048.0);
        } else {
            firstBaseline = CGRectGetMaxY(first.frame) - firstSize * (494.0 / 2048.0);
            secondBaseline = CGRectGetMaxY(second.frame) - secondSize * (494.0 / 2048.0);
            thirdBaseline = CGRectGetMaxY(third.frame) - thirdSize * (494.0 / 2048.0);
        }
        XCTAssertEqualWithAccuracy(firstBaseline, secondBaseline, 2.0);
        XCTAssertEqualWithAccuracy(secondBaseline, thirdBaseline, 2.0);
        [app terminate];
    }
}

@end
