#import "AppDelegate.h"
#include <stdio.h>

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    printf("SCN_EVENT launch window=%d root=%s\n", self.window != nil,
           self.window.rootViewController ? object_getClassName(self.window.rootViewController) : "none");
    return YES;
}
@end
