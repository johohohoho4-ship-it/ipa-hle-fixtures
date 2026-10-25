#import "AppDelegate.h"
#import "Controllers.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [[Controls1Controller alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
