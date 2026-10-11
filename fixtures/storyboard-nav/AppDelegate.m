#import "AppDelegate.h"
#include <stdio.h>

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    UIViewController *root = self.window.rootViewController;
    printf("SB_EVENT launch window=%d root=%s top=%s\n", self.window != nil, root ? object_getClassName(root) : "none",
           [root isKindOfClass:UINavigationController.class]
               ? object_getClassName(((UINavigationController *)root).topViewController) : "none");
    return YES;
}
@end
