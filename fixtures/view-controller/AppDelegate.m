#import "AppDelegate.h"
#import "ViewController.h"
#include <stdio.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    ViewController *root = [[ViewController alloc] init];
    printf("VC_BOUNDARY launch beforeRoot loaded=%d\n", root.isViewLoaded);
    self.window.rootViewController = root;
    printf("VC_BOUNDARY launch afterRoot loaded=%d\n", root.isViewLoaded);
    [self.window makeKeyAndVisible];
    printf("VC_BOUNDARY launch afterShow loaded=%d\n", root.isViewLoaded);
    printf("VC_BOUNDARY launch return\n");
    return YES;
}

@end
