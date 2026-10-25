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

- (void)expectStatus:(NSString *)text app:(XCUIApplication *)app {
    XCUIElement *label = app.staticTexts[@"tb.status"];
    NSPredicate *match = [NSPredicate predicateWithFormat:@"label == %@", text];
    [self waitForExpectations:@[[self expectationForPredicate:match evaluatedWithObject:label handler:nil]] timeout:20];
}

- (void)testTabsSelectAndBadges {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    [self expectStatus:@"TB_DONE selected=0" app:app];
    [self shot:app name:@"1-one"];

    [app.tabBars.buttons[@"Two"] tap];
    [self expectStatus:@"TB_DONE selected=1" app:app];
    [self shot:app name:@"2-two"];

    [app.tabBars.buttons[@"One"] tap];
    [self expectStatus:@"TB_DONE selected=0" app:app];
    [self shot:app name:@"3-one-again"];
}

@end
