#import "AppDelegate.h"
#include <stdio.h>

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    printf("SPV_EVENT launch window=%d root=%s\n", self.window != nil,
           self.window.rootViewController ? object_getClassName(self.window.rootViewController) : "none");
    fflush(stdout);
    return YES;
}
@end
