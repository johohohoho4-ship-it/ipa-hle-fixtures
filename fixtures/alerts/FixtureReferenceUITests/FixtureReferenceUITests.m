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
    XCUIElement *label = app.staticTexts[@"alerts.status"];
    NSPredicate *match = [NSPredicate predicateWithFormat:@"label == %@", text];
    [self waitForExpectations:@[[self expectationForPredicate:match evaluatedWithObject:label handler:nil]] timeout:20];
}

- (void)testAlertSheetAndMenu {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    XCTAssertTrue([app.staticTexts[@"alerts.status"] waitForExistenceWithTimeout:15]);
    [self shot:app name:@"1-start"];

    [app.buttons[@"alerts.alert"] tap];
    XCUIElement *alert = app.alerts[@"Alert"];
    XCTAssertTrue([alert waitForExistenceWithTimeout:10]);
    [self shot:app name:@"2-alert"];
    [alert.buttons[@"OK"] tap];
    [self expectStatus:@"ALERT_OK" app:app];
    [self shot:app name:@"3-alert-ok"];

    [app.buttons[@"alerts.sheet"] tap];
    XCUIElement *sheet = app.sheets.firstMatch;
    XCTAssertTrue([sheet waitForExistenceWithTimeout:10]);
    [self shot:app name:@"4-sheet"];
    [sheet.buttons[@"Cancel"] tap];
    [self expectStatus:@"SHEET_CANCEL" app:app];
    [self shot:app name:@"5-sheet-cancel"];

    [app.buttons[@"alerts.menu"] tap];
    XCUIElement *alpha = app.buttons[@"Alpha"];
    XCTAssertTrue([alpha waitForExistenceWithTimeout:10]);
    [alpha tap];
    [self expectStatus:@"MENU_ALPHA" app:app];
    [self shot:app name:@"6-menu-alpha"];
}

@end
