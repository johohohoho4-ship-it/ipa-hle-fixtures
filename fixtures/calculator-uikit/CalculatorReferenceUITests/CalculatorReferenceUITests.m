#import <XCTest/XCTest.h>

@interface CalculatorReferenceUITests : XCTestCase
@end

@implementation CalculatorReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)testAdditionAndCapture {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *display = app.staticTexts[@"calculator.display"];
    XCTAssertTrue([display waitForExistenceWithTimeout:15.0], @"Calculator display must appear at launch");
    XCTAssertEqualObjects(display.label, @"0");

    [app.buttons[@"calculator.button.7"] tap];
    [app.buttons[@"calculator.button.+"] tap];
    [app.buttons[@"calculator.button.5"] tap];
    [app.buttons[@"calculator.button.="] tap];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label == %@", @"12"];
    XCTestExpectation *expectation = [self expectationForPredicate:predicate evaluatedWithObject:display handler:nil];
    [self waitForExpectations:@[expectation] timeout:10.0];
    XCTAssertEqualObjects(display.label, @"12");

    XCUIScreenshot *capturedScreen = [[XCUIScreen mainScreen] screenshot];
    XCTAttachment *screenshot = [XCTAttachment attachmentWithScreenshot:capturedScreen];
    screenshot.name = @"calculator-7-plus-5";
    screenshot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:screenshot];
}

@end
