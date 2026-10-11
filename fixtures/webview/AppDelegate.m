#import "AppDelegate.h"
#import "Controllers.h"
#include <stdio.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [[WebController alloc] init];
    [self.window makeKeyAndVisible];
    printf("WV_EVENT launch\n");
    return YES;
}

@end
