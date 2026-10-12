#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase
@end
@implementation FixtureReferenceUITests
- (void)testSerializationReference {
    self.continueAfterFailure = NO;
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    XCUIElement *status = app.staticTexts[@"serialization.status"];
    XCTAssertTrue([status waitForExistenceWithTimeout:30.0]);
    XCTAssertEqualObjects(status.label, @"SERIALIZATION_OK");
    XCTAttachment *image = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    image.name = @"serialization";
    image.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:image];
}
@end
