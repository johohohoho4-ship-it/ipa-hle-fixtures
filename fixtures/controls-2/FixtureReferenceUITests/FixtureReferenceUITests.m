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

- (void)testControlsAndSearch {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    XCTAssertTrue([app.staticTexts[@"f14.status"] waitForExistenceWithTimeout:15]);
    [self shot:app name:@"1-start"];

    XCUIElement *search = app.searchFields.firstMatch;
    XCTAssertTrue([search waitForExistenceWithTimeout:10]);
    [search tap];
    [search typeText:@"abc"];
    XCUIElement *label = app.staticTexts[@"f14.status"];
    NSPredicate *match = [NSPredicate predicateWithFormat:@"label == %@", @"SEARCH=abc"];
    [self waitForExpectations:@[[self expectationForPredicate:match evaluatedWithObject:label handler:nil]] timeout:20];
    [self shot:app name:@"2-search"];
}

@end
