#import <XCTest/XCTest.h>

@interface UIKitFormReferenceUITests : XCTestCase
@end

@implementation UIKitFormReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)testGreetingInteraction {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *nameField = app.textFields[@"uikitForm.name"];
    XCTAssertTrue([nameField waitForExistenceWithTimeout:20.0], @"Name field must exist on launch");

    XCUIElement *result = app.staticTexts[@"uikitForm.result"];
    XCTAssertTrue([result waitForExistenceWithTimeout:5.0], @"Result label must exist");
    XCTAssertEqualObjects(result.label, @"Noch nichts übernommen.");

    [nameField tap];
    [nameField typeText:@"Mila\n"];

    XCUIElement *enthusiasticSwitch = app.switches[@"uikitForm.enthusiastic"];
    XCTAssertTrue([enthusiasticSwitch waitForExistenceWithTimeout:5.0], @"Greeting switch must exist");
    [enthusiasticSwitch tap];

    XCUIElement *submitButton = app.buttons[@"uikitForm.submit"];
    XCTAssertTrue([submitButton waitForExistenceWithTimeout:5.0], @"Greeting button must exist");
    [submitButton tap];

    NSString *expected = @"Hallo, Mila! Schön, dass du da bist.";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label == %@", expected];
    XCTestExpectation *expectation = [self expectationForPredicate:predicate evaluatedWithObject:result handler:nil];
    [self waitForExpectations:@[expectation] timeout:10.0];
    XCTAssertEqualObjects(result.label, expected);

    XCUIScreenshot *capturedScreen = [[XCUIScreen mainScreen] screenshot];
    XCTAttachment *screenshot = [XCTAttachment attachmentWithScreenshot:capturedScreen];
    screenshot.name = @"greeting-mila-extended";
    screenshot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:screenshot];
}

@end
