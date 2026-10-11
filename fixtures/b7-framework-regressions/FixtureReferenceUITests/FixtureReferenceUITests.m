#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)testFrameworkGroupsAndPersistenceAcrossRelaunch {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *status = app.staticTexts[@"b7.status"];
    XCTAssertTrue([status waitForExistenceWithTimeout:30.0], @"The framework groups must report their result");
    XCTAssertEqualObjects(status.label, @"B7_OK", @"Failed framework checks: %@", status.label);

    XCUIElement *sqlite = app.staticTexts[@"persistence.sqlite"];
    XCTAssertTrue([sqlite waitForExistenceWithTimeout:5.0]);
    XCTAssertEqualObjects(sqlite.label, @"Rows: 2");

    XCUIElement *counter = app.staticTexts[@"persistence.counter"];
    XCTAssertTrue([counter waitForExistenceWithTimeout:5.0]);
    NSInteger initialCount = [[counter.label componentsSeparatedByString:@" "].lastObject integerValue];
    XCUIElement *save = app.buttons[@"persistence.save"];
    XCTAssertTrue([save waitForExistenceWithTimeout:5.0]);
    [save tap];
    NSString *expectedCount = [NSString stringWithFormat:@"Count: %ld", (long)(initialCount + 1)];
    XCTAssertEqualObjects(counter.label, expectedCount);

    [app terminate];
    [app launch];
    status = app.staticTexts[@"b7.status"];
    counter = app.staticTexts[@"persistence.counter"];
    sqlite = app.staticTexts[@"persistence.sqlite"];
    XCTAssertTrue([status waitForExistenceWithTimeout:30.0]);
    XCTAssertEqualObjects(status.label, @"B7_OK", @"Failed framework checks after relaunch: %@", status.label);
    XCTAssertEqualObjects(counter.label, expectedCount);
    XCTAssertEqualObjects(sqlite.label, @"Rows: 2");

    XCTAttachment *screenshot = [XCTAttachment attachmentWithScreenshot:[app screenshot]];
    screenshot.name = @"b7-framework-regressions";
    screenshot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:screenshot];
}

@end
