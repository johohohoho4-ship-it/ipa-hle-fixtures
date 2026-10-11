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
    XCUIElement *label = app.staticTexts[@"wv.label"];
    NSPredicate *match = [NSPredicate predicateWithFormat:@"label == %@", text];
    [self waitForExpectations:@[[self expectationForPredicate:match evaluatedWithObject:label handler:nil]] timeout:15];
}
- (void)testLoadMessageAndEvaluateJavaScript {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    [self expectLabel:@"loaded" app:app];
    [self shot:app name:@"1-loaded"];
    [app.webViews.buttons[@"Send"] tap];
    [self expectLabel:@"message tap" app:app];
    [self shot:app name:@"2-message"];
    NSArray *steps = @[@[@"wv.sum", @"3"], @[@"wv.title", @"Hello"], @[@"wv.user", @"yes"], @[@"wv.json", @"dictionary"],
                       @[@"wv.undef", @"nil"], @[@"wv.throw", @"error"]];
    for (NSArray *step in steps) {
        [app.buttons[step[0]] tap];
        [self expectLabel:step[1] app:app];
    }
    [self shot:app name:@"3-after-evals"];
}
@end
