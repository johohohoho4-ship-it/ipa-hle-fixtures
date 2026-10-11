#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)testArchivesAndAtlasAreLogged {
    self.continueAfterFailure = NO;
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    XCUIElement *status = app.staticTexts[@"sk.status"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label == %@", @"SK_ARCHIVES_READY"];
    XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:status];
    XCTAssertEqual([XCTWaiter waitForExpectations:@[expectation] timeout:30.0], XCTWaiterResultCompleted);

    XCTAttachment *shot = [XCTAttachment attachmentWithScreenshot:[app screenshot]];
    shot.name = @"spritekit-archives";
    shot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:shot];
}

@end
