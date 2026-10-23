#import <XCTest/XCTest.h>

@interface CorpusUITests : XCTestCase
@end

@implementation CorpusUITests

- (void)testOpensASeededTask {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *seeded = app.staticTexts[@"Example work task"];
    XCTAssertTrue([seeded waitForExistenceWithTimeout:30],
                  @"The task seeded into Core Data must appear in the table");

    [seeded tap];

    XCUIElement *name = app.textFields.firstMatch;
    XCTAssertTrue([name waitForExistenceWithTimeout:20], @"The detail view must show the name field");
    NSPredicate *showsTask = [NSPredicate predicateWithFormat:@"value == %@", @"Example work task"];
    XCTNSPredicateExpectation *expectation =
        [[XCTNSPredicateExpectation alloc] initWithPredicate:showsTask object:name];
    XCTAssertEqual([XCTWaiter waitForExpectations:@[expectation] timeout:10], XCTWaiterResultCompleted,
                   @"The detail field must carry the selected task name");

    XCTAttachment *screenshot = [XCTAttachment attachmentWithScreenshot:app.screenshot];
    screenshot.name = @"corpus-taskmanager-detail";
    screenshot.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:screenshot];
}

@end
