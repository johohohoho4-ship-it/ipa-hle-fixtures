#import "AppDelegate.h"
#import "ViewControllers.h"

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    GuideArchiveViewController *root = [storyboard instantiateInitialViewController];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:root];
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = navigation;
    [self.window makeKeyAndVisible];
    return YES;
}
@end
