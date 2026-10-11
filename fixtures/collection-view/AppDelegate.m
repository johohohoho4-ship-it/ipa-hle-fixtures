#import "AppDelegate.h"
#import "ViewController.h"
#include <stdio.h>
@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
#if TARGET_OS_SIMULATOR
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ipa-hle-console.log"];
    freopen(path.UTF8String, "w", stdout); setvbuf(stdout, NULL, _IONBF, 0);
#endif
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [[ViewController alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}
@end
