#import "Controllers.h"
#include <stdio.h>

@implementation NavController
- (const char *)eventName { return "?"; }
- (void)viewDidLoad { [super viewDidLoad]; printf("NAV_EVENT %s load nav=%d\n", self.eventName, self.navigationController != nil); }
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a]; printf("NAV_EVENT %s willAppear animated=%d\n", self.eventName, a); }
- (void)viewDidAppear:(BOOL)a { [super viewDidAppear:a]; printf("NAV_EVENT %s didAppear animated=%d\n", self.eventName, a); }
- (void)viewWillDisappear:(BOOL)a { [super viewWillDisappear:a]; printf("NAV_EVENT %s willDisappear animated=%d\n", self.eventName, a); }
- (void)viewDidDisappear:(BOOL)a { [super viewDidDisappear:a]; printf("NAV_EVENT %s didDisappear animated=%d\n", self.eventName, a); }
- (void)didMoveToParentViewController:(UIViewController *)parent { [super didMoveToParentViewController:parent]; printf("NAV_EVENT %s didMove parent=%d\n", self.eventName, parent != nil); }

- (UIButton *)addButton:(NSString *)title identifier:(NSString *)identifier above:(UIView *)above action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:title forState:UIControlStateNormal];
    button.accessibilityIdentifier = identifier;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [button.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:20],
        [button.widthAnchor constraintEqualToConstant:200],
        [button.heightAnchor constraintEqualToConstant:44],
        above ? [button.topAnchor constraintEqualToAnchor:above.bottomAnchor constant:10]
              : [button.topAnchor constraintEqualToAnchor:safe.topAnchor constant:20],
    ]];
    return button;
}
@end

@implementation RootController
- (const char *)eventName { return "root"; }
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Root";
    self.view.backgroundColor = UIColor.whiteColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(add:)];
    UIButton *push = [self addButton:@"Push" identifier:@"nav.push" above:nil action:@selector(push:)];
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = @"Root screen";
    label.accessibilityIdentifier = @"nav.label";
    [self.view addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:push.leadingAnchor],
        [label.topAnchor constraintEqualToAnchor:push.bottomAnchor constant:10],
    ]];
}
- (void)add:(id)sender {
    printf("NAV_EVENT root add\n");
    for (UIView *view in self.view.subviews) if ([view isKindOfClass:UILabel.class]) ((UILabel *)view).text = @"Added";
}
- (void)push:(id)sender {
    LevelController *next = [[LevelController alloc] init];
    next.level = 2;
    [self.navigationController pushViewController:next animated:NO];
}
@end

@implementation LevelController
- (const char *)eventName { return self.level == 2 ? "level2" : self.level == 3 ? "level3" : "level4"; }
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [NSString stringWithFormat:@"Level %d", self.level];
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.view.backgroundColor = UIColor.whiteColor;
    UIButton *last = nil;
    if (self.level == 2) {
        self.navigationItem.backButtonTitle = @"Back2";
        last = [self addButton:@"Push" identifier:@"nav.push" above:last action:@selector(push:)];
    } else if (self.level == 3) {
        last = [self addButton:@"Pop" identifier:@"nav.pop" above:last action:@selector(pop:)];
        last = [self addButton:@"Pop to root" identifier:@"nav.root" above:last action:@selector(popToRoot:)];
        last = [self addButton:@"Pop to Level 2" identifier:@"nav.popto" above:last action:@selector(popToLevel2:)];
        last = [self addButton:@"Replace stack" identifier:@"nav.replace" above:last action:@selector(replace:)];
    } else {
        self.navigationItem.hidesBackButton = YES;
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
        last = [self addButton:@"Hide bar" identifier:@"nav.hide" above:last action:@selector(toggleBar:)];
    }
}
- (void)push:(id)sender {
    LevelController *next = [[LevelController alloc] init];
    next.level = self.level + 1;
    [self.navigationController pushViewController:next animated:NO];
}
- (void)pop:(id)sender {
    UIViewController *popped = [self.navigationController popViewControllerAnimated:NO];
    printf("NAV_EVENT %s popped=%s\n", self.eventName, popped == self ? "self" : "other");
}
- (void)popToLevel2:(id)sender {
    NSArray *popped = [self.navigationController popToViewController:self.navigationController.viewControllers[1] animated:NO];
    printf("NAV_EVENT %s popToLevel2 count=%lu\n", self.eventName, (unsigned long)popped.count);
}
- (void)replace:(id)sender {
    LevelController *next = [[LevelController alloc] init];
    next.level = 4;
    [self.navigationController setViewControllers:@[self.navigationController.viewControllers.firstObject, next] animated:NO];
    printf("NAV_EVENT %s replaced stack=%lu\n", self.eventName, (unsigned long)self.navigationController.viewControllers.count);
}
- (void)done:(id)sender {
    printf("NAV_EVENT %s done\n", self.eventName);
    [self.navigationController popToRootViewControllerAnimated:NO];
}
- (void)toggleBar:(id)sender {
    BOOL hidden = !self.navigationController.isNavigationBarHidden;
    [self.navigationController setNavigationBarHidden:hidden animated:NO];
    printf("NAV_EVENT %s bar hidden=%d\n", self.eventName, hidden);
}
- (void)popToRoot:(id)sender {
    NSArray *popped = [self.navigationController popToRootViewControllerAnimated:NO];
    printf("NAV_EVENT %s popToRoot count=%lu\n", self.eventName, (unsigned long)popped.count);
}
@end
