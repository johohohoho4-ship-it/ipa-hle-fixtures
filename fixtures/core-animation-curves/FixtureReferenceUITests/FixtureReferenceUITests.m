#import <XCTest/XCTest.h>
@interface FixtureReferenceUITests : XCTestCase
@end
@implementation FixtureReferenceUITests
- (void)setUp { [super setUp]; self.continueAfterFailure=NO; }
- (void)expect:(XCUIApplication *)app stage:(NSInteger)stage {
    NSPredicate *predicate=[NSPredicate predicateWithFormat:@"label == %@",[NSString stringWithFormat:@"Stage %ld",(long)stage]];
    [self expectationForPredicate:predicate evaluatedWithObject:app.staticTexts[@"curve.status"] handler:nil];
    [self waitForExpectationsWithTimeout:5 handler:nil];
    XCTAttachment *shot=[XCTAttachment attachmentWithScreenshot:app.screenshot];
    shot.name=[NSString stringWithFormat:@"curve-stage%ld",(long)stage];
    shot.lifetime=XCTAttachmentLifetimeKeepAlways; [self addAttachment:shot];
}
- (void)testNamedAndCustomTimingCurves {
    XCUIApplication *app=[[XCUIApplication alloc] init]; [app launch]; [self expect:app stage:0];
    for(NSInteger i=1;i<=4;i++) {
        [app.buttons[[NSString stringWithFormat:@"curve.step%ld",(long)i]] tap];
        [self expect:app stage:i];
    }
}
@end
