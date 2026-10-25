#import "AppDelegate.h"
#import "Controllers.h"

@interface AppDelegate () <UITabBarControllerDelegate>
@property (nonatomic, strong) UITabBarController *tabs;
@end

@implementation AppDelegate

- (void)updateLabels {
    NSString *text = [NSString stringWithFormat:@"TB_DONE selected=%ld", (long)self.tabs.selectedIndex];
    for (TabController *controller in self.tabs.viewControllers) {
        controller.statusLabel.text = text;
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.tabs = [[UITabBarController alloc] init];
    NSMutableArray<UIViewController *> *controllers = [NSMutableArray array];
    for (NSString *name in @[@"One", @"Two", @"Three"]) {
        TabController *controller = [[TabController alloc] init];
        controller.name = name;
        controller.title = name;
        [controllers addObject:controller];
    }
    self.tabs.viewControllers = controllers;
    self.tabs.delegate = self;

    UITabBarItem *first = self.tabs.tabBar.items[0];
    UITabBarItem *second = self.tabs.tabBar.items[1];
    UITabBarItem *third = self.tabs.tabBar.items[2];
    first.badgeValue = @"1";
    second.badgeValue = @"2";
    third.enabled = NO;
    first.titlePositionAdjustment = UIOffsetMake(0, -2);
    self.tabs.tabBar.itemPositioning = UITabBarItemPositioningFill;
    self.tabs.tabBar.barTintColor = UIColor.blackColor;
    self.tabs.tabBar.unselectedItemTintColor = UIColor.grayColor;

    TBPrint(@"TB_START tabs=%lu selected=%ld",
            (unsigned long)self.tabs.viewControllers.count, (long)self.tabs.selectedIndex);
    for (NSUInteger index = 0; index < self.tabs.tabBar.items.count; index++) {
        UITabBarItem *item = self.tabs.tabBar.items[index];
        TBPrint(@"TB_ITEM index=%lu title=%@ badge=%@ enabled=%d offset=%.1f,%.1f",
                (unsigned long)index, item.title ?: @"none", item.badgeValue ?: @"none",
                item.isEnabled, item.titlePositionAdjustment.horizontal,
                item.titlePositionAdjustment.vertical);
    }
    TBPrint(@"TB_SELECTED index=%ld controller=%@", (long)self.tabs.selectedIndex,
            ((UIViewController *)self.tabs.selectedViewController).title ?: @"none");
    TBPrint(@"TB_POSITIONING %@", self.tabs.tabBar.itemPositioning == UITabBarItemPositioningFill
            ? @"fill" : (self.tabs.tabBar.itemPositioning == UITabBarItemPositioningCentered
                         ? @"centered" : @"automatic"));
    CGFloat bar[4] = {0, 0, 0, 0};
    CGFloat unselected[4] = {0, 0, 0, 0};
    [self.tabs.tabBar.barTintColor getRed:&bar[0] green:&bar[1] blue:&bar[2] alpha:&bar[3]];
    [self.tabs.tabBar.unselectedItemTintColor getRed:&unselected[0] green:&unselected[1]
                                                blue:&unselected[2] alpha:&unselected[3]];
    TBPrint(@"TB_TINT bar=%.1f,%.1f,%.1f,%.1f unselected=%.1f,%.1f,%.1f,%.1f",
            bar[0], bar[1], bar[2], bar[3], unselected[0], unselected[1], unselected[2], unselected[3]);
    TBPrint(@"TB_DONE");

    self.window.rootViewController = self.tabs;
    [self.window makeKeyAndVisible];
    [self updateLabels];
    return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController
    didSelectViewController:(UIViewController *)viewController {
    TBPrint(@"TB_DELEGATE index=%ld controller=%@", (long)tabBarController.selectedIndex,
            viewController.title ?: @"none");
    [self updateLabels];
}

@end
