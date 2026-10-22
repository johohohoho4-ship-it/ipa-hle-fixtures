#import "AppDelegate.h"
#import "ViewControllers.h"
#include <stdio.h>

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    printf("GA_APP launch window=%d\n", self.window != nil);
    UIViewController *root = self.window.rootViewController;
    if (root && ![root isKindOfClass:UINavigationController.class]) {
        UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:root];
        self.window.rootViewController = navigation;
    }
    return YES;
}
@end
