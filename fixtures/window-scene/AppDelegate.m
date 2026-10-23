#import "AppDelegate.h"
#import "ViewController.h"
#include <stdio.h>
#include <stdlib.h>

static BOOL ConfigMatrixEnabled(void) {
    const char *value = getenv("WS_CONFIG_MATRIX");
    return value != NULL && value[0] == '1';
}

static const char *CStringOrNil(NSString *value) {
    return value.length ? value.UTF8String : "(nil)";
}

static const char *DelegateName(UISceneConfiguration *config) {
    Class cls = config.delegateClass;
    return cls ? NSStringFromClass(cls).UTF8String : "(nil)";
}

static void PrintConfiguration(const char *phase, NSInteger index, UISceneConfiguration *config) {
    printf("WS_CFG phase=%s index=%ld name=%s role=%s delegate=%s ptr=%p\n",
           phase, (long)index, CStringOrNil(config.name), CStringOrNil(config.role),
           DelegateName(config), (__bridge void *)config);
}

static void PrintWindows(const char *phase, UIWindowScene *scene, UIWindow *root) {
    UIApplication *app = UIApplication.sharedApplication;
    printf("WS_WINDOWS phase=%s appCount=%lu sceneCount=%lu appHasRoot=%d sceneHasRoot=%d "
           "appKeyNil=%d sceneKeyNil=%d appKeyIsRoot=%d sceneKeyIsRoot=%d\n",
           phase, (unsigned long)app.windows.count, (unsigned long)scene.windows.count,
           root && [app.windows containsObject:root], root && [scene.windows containsObject:root],
           app.keyWindow == nil, scene.keyWindow == nil,
           root && app.keyWindow == root, root && scene.keyWindow == root);
}

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    printf("WS_APP launch\n");
    if (ConfigMatrixEnabled()) {
        // F1 measurement (Sol, 2026-10-23): open sessions before the scene
        // connects, for cold and repeated starts.
        printf("WS_LAUNCH matrix=1 openSessions=%lu\n", (unsigned long)application.openSessions.count);
    }
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
    if (ConfigMatrixEnabled()) {
        // F1 measurement: construct and read the configurations in willConnect,
        // then read the same objects again after the connection. Reading
        // session.configuration inside willConnect is deliberately deferred;
        // it is the API the measurement is about.
        NSMutableArray<UISceneConfiguration *> *configs = [NSMutableArray array];
        [configs addObject:[[UISceneConfiguration alloc] initWithName:@"Main"
                                                         sessionRole:UIWindowSceneSessionRoleApplication]];
        [configs addObject:[[UISceneConfiguration alloc] initWithName:@"Probe"
                                                         sessionRole:UIWindowSceneSessionRoleApplication]];
        [configs addObject:[[UISceneConfiguration alloc] initWithName:@"Second"
                                                         sessionRole:UIWindowSceneSessionRoleApplication]];
        @try {
            [configs addObject:[[UISceneConfiguration alloc] initWithName:nil
                                                             sessionRole:UIWindowSceneSessionRoleApplication]];
        } @catch (NSException *exception) {
            printf("WS_CFG phase=initNil error=%s\n", exception.name.UTF8String);
        }
        self.configMatrix = configs;
        self.session = session;
        for (NSUInteger index = 0; index < configs.count; index++) {
            PrintConfiguration("willConnect", index, configs[index]);
        }
    }
    PrintWindows("beforeWindow", windowScene, nil);
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    PrintWindows("afterConstructor", windowScene, self.window);
    printf("WS_CONNECT sameSession=%d assigned=%d sceneClass=%s\n", scene.session == session,
           self.window.windowScene == windowScene, NSStringFromClass(scene.class).UTF8String);
    // Sol 18be622e: the native start does not log WS_CONFIG from
    // application:configurationForConnectingSceneSession:. Measure the role of a
    // configuration object built here, outside that callback, so both the
    // controller and the stored role of an explicit configuration are covered.
    UISceneConfiguration *probe = [[UISceneConfiguration alloc] initWithName:@"Probe" sessionRole:session.role];
    printf("WS_ROLE phase=willConnect sessionRole=%s configRole=%s name=%s\n",
           session.role.UTF8String, probe.role.UTF8String, probe.name.UTF8String);
    self.window.rootViewController = [ViewController new];
    [self.window makeKeyAndVisible];
    PrintWindows("afterKey", windowScene, self.window);
}

- (void)logMatrixAfterConnect {
    if (!self.configMatrix) return;
    for (NSUInteger index = 0; index < self.configMatrix.count; index++) {
        PrintConfiguration("afterConnect", index, self.configMatrix[index]);
    }
    UISceneConfiguration *actual = self.session.configuration;
    printf("WS_CFG phase=session name=%s role=%s delegate=%s ptr=%p\n",
           actual ? CStringOrNil(actual.name) : "(nil)",
           actual ? CStringOrNil(actual.role) : "(nil)",
           actual ? DelegateName(actual) : "(nil)",
           (__bridge void *)actual);
}
@end
