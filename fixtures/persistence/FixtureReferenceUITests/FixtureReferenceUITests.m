#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase
@end
@implementation FixtureReferenceUITests
- (void)setUp { [super setUp]; self.continueAfterFailure = NO; }
- (void)shot:(XCUIApplication *)app name:(NSString *)name {
    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name = name;
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
}
- (void)expectLabel:(NSString *)text app:(XCUIApplication *)app {
    XCUIElement *label = app.staticTexts[@"p.label"];
    NSPredicate *match = [NSPredicate predicateWithFormat:@"label == %@", text];
    [self waitForExpectations:@[[self expectationForPredicate:match evaluatedWithObject:label handler:nil]] timeout:15];
}
- (void)testCountersSurviveARestart {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    [self expectLabel:@"file 0 defaults 0" app:app];
    [app.buttons[@"p.count"] tap];
    [app.buttons[@"p.count"] tap];
    [self expectLabel:@"file 2 defaults 2" app:app];
    [self shot:app name:@"1-counted"];
    [app terminate];
    [app launch];
    [self expectLabel:@"file 2 defaults 2" app:app];
    [self shot:app name:@"2-after-restart"];
    [app.buttons[@"p.count"] tap];
    [self expectLabel:@"file 3 defaults 3" app:app];
}
@end
