#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)testSessionPlayerAndSystemSound {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *title = app.staticTexts[@"audio.title"];
    XCTAssertTrue([title waitForExistenceWithTimeout:15.0], @"The audio fixture must appear");

    XCUIElement *status = app.staticTexts[@"audio.status"];
    XCTAssertTrue([status waitForExistenceWithTimeout:5.0]);
    XCTAssertEqualObjects(status.label, @"AUDIO_OK");

    XCTAttachment *screenshot = [XCTAttachment attachmentWithScreenshot:[app screenshot]];
    screenshot.name = @"audio-session-player-system-sound";
    screenshot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:screenshot];
}

@end
