#import "AppDelegate.h"
#import "ViewControllers.h"
#include <stdio.h>

static void log_controller(const char *event, UIViewController *vc, NSString *mode, NSString *access) {
    if (!vc.isViewLoaded) {
        printf("GEOM_%s mode=%s access=%s loaded=0\n", event, mode.UTF8String, access.UTF8String);
        return;
    }
    UIView *view = vc.view;
    CGRect bounds = view.bounds;
    CGRect frame = view.frame;
    printf("GEOM_%s mode=%s access=%s loaded=1 bounds=%.1f,%.1f,%.1f,%.1f "
           "frame=%.1f,%.1f,%.1f,%.1f window=%d\n",
           event, mode.UTF8String, access.UTF8String,
           bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height,
           frame.origin.x, frame.origin.y, frame.size.width, frame.size.height, view.window != nil);
}

static void log_window(const char *event) {
    UIWindow *window = ((AppDelegate *)UIApplication.sharedApplication.delegate).window;
    CGRect frame = window.frame;
    CGRect bounds = window.bounds;
    printf("GEOM_%s frame=%.1f,%.1f,%.1f,%.1f bounds=%.1f,%.1f,%.1f,%.1f hidden=%d key=%d\n",
           event, frame.origin.x, frame.origin.y, frame.size.width, frame.size.height,
           bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height,
           window.hidden, window.isKeyWindow);
}

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSDictionary<NSString *, NSString *> *environment = NSProcessInfo.processInfo.environment;
    NSString *mode = environment[@"GEOM_MODE"] ?: @"plain";
    NSString *access = environment[@"GEOM_ACCESS"] ?: @"lazy";
    CGRect screen = UIScreen.mainScreen.bounds;
    printf("GEOM_START mode=%s access=%s screen=%.1f,%.1f,%.1f,%.1f\n",
           mode.UTF8String, access.UTF8String,
           screen.origin.x, screen.origin.y, screen.size.width, screen.size.height);

    self.window = [[UIWindow alloc] initWithFrame:screen];
    log_window("WINDOW_BEFORE_ROOT");

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    RootGeometryViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"root"];
    vc.geomMode = mode;
    vc.geomAccess = access;
    log_controller("VC_INSTANTIATED", vc, mode, access);

    if ([access isEqualToString:@"eager"]) {
        UIView *eager = vc.view;                          // the eager access before any window
        CGRect bounds = eager.bounds;
        CGRect frame = eager.frame;
        printf("GEOM_EAGER mode=%s bounds=%.1f,%.1f,%.1f,%.1f frame=%.1f,%.1f,%.1f,%.1f window=%d\n",
               mode.UTF8String, bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height,
               frame.origin.x, frame.origin.y, frame.size.width, frame.size.height, eager.window != nil);
    }

    UIViewController *root = vc;
    if ([mode isEqualToString:@"nav"]) {
        root = [[UINavigationController alloc] initWithRootViewController:vc];
        printf("GEOM_NAV wrapped=1 mode=%s\n", mode.UTF8String);
    }
    log_controller("ROOT_BEFORE_SET", vc, mode, access);
    self.window.rootViewController = root;
    log_controller("ROOT_AFTER_SET", vc, mode, access);
    log_window("WINDOW_AFTER_ROOT");

    [self.window makeKeyAndVisible];
    log_controller("KEY_AFTER", vc, mode, access);
    log_window("WINDOW_AFTER_KEY");
    return YES;
}

@end
