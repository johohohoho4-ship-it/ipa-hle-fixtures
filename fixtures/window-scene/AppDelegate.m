#import "AppDelegate.h"
#import "ViewController.h"
#include <stdio.h>

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    printf("WS_APP launch\n");
    return YES;
}
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
    UISceneConfiguration *config = [[UISceneConfiguration alloc] initWithName:@"Main" sessionRole:session.role];
    config.delegateClass = [SceneDelegate class];
    printf("WS_CONFIG role=%s configRole=%s name=%s\n", session.role.UTF8String,
           config.role.UTF8String, config.name.UTF8String);
    return config;
}
@end

@implementation SceneDelegate
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    printf("WS_CONNECT sameSession=%d assigned=%d sceneClass=%s\n", scene.session == session,
           self.window.windowScene == windowScene, NSStringFromClass(scene.class).UTF8String);
    self.window.rootViewController = [ViewController new];
    [self.window makeKeyAndVisible];
}
@end
