#import "AppDelegate.h"
#import "Controllers.h"
#include <stdio.h>

static const char *Name(UIViewController *vc) {
    return [vc respondsToSelector:@selector(eventName)] ? [(NavController *)vc eventName] : "?";
}

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[RootController alloc] init]];
    nav.navigationBar.prefersLargeTitles = YES;
    nav.delegate = self;
    printf("NAV_EVENT launch stack=%lu\n", (unsigned long)nav.viewControllers.count);
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    printf("NAV_EVENT delegate willShow %s animated=%d\n", Name(viewController), animated);
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    printf("NAV_EVENT delegate didShow %s animated=%d stack=%lu\n", Name(viewController), animated, (unsigned long)navigationController.viewControllers.count);
}

@end
