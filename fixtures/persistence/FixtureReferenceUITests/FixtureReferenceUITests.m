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

- (void)waitForDone:(XCUIApplication *)app {
    XCUIElement *label = app.staticTexts[@"persistence.status"];
    XCTAssertTrue([label waitForExistenceWithTimeout:15]);
    NSPredicate *done = [NSPredicate predicateWithFormat:@"label == %@", @"PERS_DONE"];
    [self waitForExpectations:@[[self expectationForPredicate:done evaluatedWithObject:label handler:nil]] timeout:20];
}

- (void)testValuesSurviveARestart {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    app.launchArguments = @[@"-PERSReset", @"YES"];
    [app launch];
    [self waitForDone:app];
    [self shot:app name:@"1-first"];

    [app terminate];
    app.launchArguments = @[];
    [app launch];
    [self waitForDone:app];
    [self shot:app name:@"2-after-restart"];
}

@end
