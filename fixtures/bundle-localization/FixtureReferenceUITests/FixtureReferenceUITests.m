#import <XCTest/XCTest.h>

@interface FixtureReferenceUITests : XCTestCase
@end

@implementation FixtureReferenceUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)assertLocalization:(NSString *)language
                    locale:(NSString *)locale
             expectedGreeting:(NSString *)expectedGreeting
             expectedDisplayName:(NSString *)expectedDisplayName
              expectedSingular:(NSString *)expectedSingular
                expectedPlural:(NSString *)expectedPlural
           expectedImageRegion:(NSString *)expectedImageRegion {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    app.launchArguments = @[
        @"-AppleLanguages", [NSString stringWithFormat:@"(%@)", language],
        @"-AppleLocale", locale
    ];
    [app launch];

    XCUIElement *greeting = app.staticTexts[@"bundle.greeting"];
    XCTAssertTrue([greeting waitForExistenceWithTimeout:15.0]);
    XCTAssertEqualObjects(greeting.label, expectedGreeting);

    XCUIElement *displayName = app.staticTexts[@"bundle.display-name"];
    XCTAssertTrue(displayName.exists);
    XCTAssertEqualObjects(displayName.label, [@"Display name: " stringByAppendingString:expectedDisplayName]);

    XCUIElement *singular = app.staticTexts[@"bundle.plural-one"];
    XCUIElement *plural = app.staticTexts[@"bundle.plural-other"];
    XCTAssertTrue(singular.exists);
    XCTAssertTrue(plural.exists);
    XCTAssertEqualObjects(singular.label, expectedSingular);
    XCTAssertEqualObjects(plural.label, expectedPlural);

    XCUIElement *image = app.images[@"bundle.localized-image"];
    XCTAssertTrue(image.exists, @"The localized PNG resource must load");
    XCTAssertEqualObjects(image.label, expectedImageRegion);
    XCUIElement *imagePath = app.staticTexts[@"bundle.localized-image-path"];
    XCTAssertEqualObjects(imagePath.label, [@"Image: " stringByAppendingString:expectedImageRegion]);

    XCUIElement *bundleIdentifier = app.staticTexts[@"bundle.identifier"];
    XCTAssertTrue(bundleIdentifier.exists);
    XCTAssertEqualObjects(bundleIdentifier.label, @"Bundle: org.ipahle.fixture.bundlelocalization");

    XCTAttachment *screenshot = [XCTAttachment attachmentWithScreenshot:[app screenshot]];
    screenshot.name = [NSString stringWithFormat:@"bundle-localization-%@", language];
    screenshot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:screenshot];
    [app terminate];
}

- (void)testGermanBundleLocalization {
    [self assertLocalization:@"de"
                       locale:@"de_DE"
                expectedGreeting:@"Hallo aus dem Bundle."
             expectedDisplayName:@"Lokalisierung"
               expectedSingular:@"1 Element"
                 expectedPlural:@"2 Elemente"
            expectedImageRegion:@"de.lproj"];
}

- (void)testEnglishBundleLocalization {
    [self assertLocalization:@"en"
                       locale:@"en_US"
                expectedGreeting:@"Hello from the bundle."
             expectedDisplayName:@"Localization"
               expectedSingular:@"1 item"
                 expectedPlural:@"2 items"
            expectedImageRegion:@"en.lproj"];
}

@end
