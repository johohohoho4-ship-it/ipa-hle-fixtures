#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

// The app reads the new trait collection one run-loop turn after the tap; wait for the
// label instead of asserting the next main-thread state.
- (void)waitForLabel:(XCUIElement *)element toEqual:(NSString *)text {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label == %@", text];
    XCTNSPredicateExpectation *expectation =
        [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:element];
    XCTAssertEqual([XCTWaiter waitForExpectations:@[expectation] timeout:5.0],
                   XCTWaiterResultCompleted, @"%@ did not become %@", element, text);
}

- (void)testTraitInheritanceDynamicColorsAndDynamicType {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *title = app.staticTexts[@"trait.title"];
    XCTAssertTrue([title waitForExistenceWithTimeout:15.0], @"The trait collection fixture must appear");

    XCUIElement *style = app.staticTexts[@"trait.style"];
    [self waitForLabel:style toEqual:@"Appearance: Dark"];

    XCUIElement *sizeClasses = app.staticTexts[@"trait.size-classes"];
    XCTAssertTrue(sizeClasses.exists);
    XCTAssertEqualObjects(sizeClasses.label, @"Size classes: 1 / 2");

    XCUIElement *dynamicType = app.staticTexts[@"trait.dynamic-type"];
    XCTAssertTrue(dynamicType.exists);
    NSArray<NSString *> *parts = [dynamicType.label componentsSeparatedByString:@" "];
    XCTAssertGreaterThan(parts.count, 2u);
    XCTAssertGreaterThan(parts[2].doubleValue, 17.0, @"The accessibility trait must enlarge the font");

    XCUIElement *toggle = app.buttons[@"trait.toggle-appearance"];
    XCTAssertTrue(toggle.isHittable);
    [toggle tap];
    [self waitForLabel:style toEqual:@"Appearance: Light"];
    XCTAttachment *lightScreenshot = [XCTAttachment attachmentWithScreenshot:[app screenshot]];
    lightScreenshot.name = @"trait-collections-light-profile";
    lightScreenshot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:lightScreenshot];
    [toggle tap];
    [self waitForLabel:style toEqual:@"Appearance: Dark"];

    XCTAttachment *screenshot = [XCTAttachment attachmentWithScreenshot:[app screenshot]];
    screenshot.name = @"trait-collections-dark-profile";
    screenshot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:screenshot];
}

@end
