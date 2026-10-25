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

- (void)expectLabel:(NSString *)text app:(XCUIApplication *)app {
    XCUIElement *label = app.staticTexts[@"cd.status"];
    NSPredicate *match = [NSPredicate predicateWithFormat:@"label == %@", text];
    [self waitForExpectations:@[[self expectationForPredicate:match evaluatedWithObject:label handler:nil]] timeout:20];
}

- (void)testCoreDataChecksSurviveARestart {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    app.launchArguments = @[@"-CDReset", @"YES"];
    [app launch];
    [self expectLabel:@"CD_DONE start=1 count=1" app:app];
    [self shot:app name:@"1-first-launch"];

    [app terminate];
    app.launchArguments = @[];
    [app launch];
    [self expectLabel:@"CD_DONE start=1 count=2" app:app];
    [self shot:app name:@"2-after-restart"];
}

@end
