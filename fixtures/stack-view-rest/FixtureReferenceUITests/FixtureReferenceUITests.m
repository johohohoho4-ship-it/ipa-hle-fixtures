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

- (void)testStackViewGettersAndRemoval {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    XCUIElement *status = app.staticTexts[@"sv.status"];
    XCTAssertTrue([status waitForExistenceWithTimeout:15]);
    NSPredicate *done = [NSPredicate predicateWithFormat:@"label == %@", @"SV_DONE"];
    [self waitForExpectations:@[[self expectationForPredicate:done evaluatedWithObject:status handler:nil]] timeout:20];
    [self shot:app name:@"1-stack"];
}

@end
