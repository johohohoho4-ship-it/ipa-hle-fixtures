#import "ViewControllers.h"
#include <stdio.h>
#include <string.h>

@implementation BadgeView
@end

@implementation CardOwner
@end

@interface NavRootViewController ()
@property (nonatomic) BOOL loggedAppear;
@end

@interface NavDetailViewController ()
@property (nonatomic) BOOL loggedAppear;
@end

@interface PlainViewController ()
@property (nonatomic) BOOL loggedAppear;
@end

static NSString *ItemName(id item) {
    return item ? NSStringFromClass([item class]) : @"none";
}

static NSString *SelName(SEL selector) {
    return selector ? NSStringFromSelector(selector) : @"none";
}

// The native values F7 needs: length, owning controller/view and the layout
// frame of both layout-support guides. Deprecated API on purpose: it is the
// surface a real iOS 18.5 app still gets for storyboard view controllers.
static void LogGuides(UIViewController *vc, const char *phase) {
    id<UILayoutSupport> top = vc.topLayoutGuide;
    id<UILayoutSupport> bottom = vc.bottomLayoutGuide;
    UILayoutGuide *topGuide = (UILayoutGuide *)top;
    UILayoutGuide *bottomGuide = (UILayoutGuide *)bottom;
    CGRect topFrame = topGuide.layoutFrame;
    CGRect bottomFrame = bottomGuide.layoutFrame;
    CGFloat status = 0;
    if (@available(iOS 13.0, *)) {
        status = vc.view.window.windowScene.statusBarManager.statusBarFrame.size.height;
    }
    printf("LG_GUIDE phase=%s vc=%s nav=%d top=%.1f bottom=%.1f topClass=%s bottomClass=%s "
           "topOwner=%d bottomOwner=%d topOwnerView=%s topFrame=%.1f,%.1f,%.1f,%.1f "
           "bottomFrame=%.1f,%.1f,%.1f,%.1f status=%.1f safeTop=%.1f safeBottom=%.1f\n",
           phase, object_getClassName(vc), vc.navigationController != nil,
           top.length, bottom.length,
           object_getClassName(top), object_getClassName(bottom),
           top.owningViewController == vc, bottom.owningViewController == vc,
           object_getClassName(topGuide.owningView),
           topFrame.origin.x, topFrame.origin.y, topFrame.size.width, topFrame.size.height,
           bottomFrame.origin.x, bottomFrame.origin.y, bottomFrame.size.width, bottomFrame.size.height,
           status, vc.view.safeAreaInsets.top, vc.view.safeAreaInsets.bottom);

    // Support constraints that mention either guide, sorted so repeated runs
    // print the same order.
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    for (NSLayoutConstraint *c in vc.view.constraints) {
        if (c.firstItem != top && c.secondItem != top && c.firstItem != bottom && c.secondItem != bottom) {
            continue;
        }
        const char *guide = (c.firstItem == top || c.secondItem == top) ? "top" : "bottom";
        [lines addObject:[NSString stringWithFormat:
            @"LG_CONSTRAINT phase=%s guide=%s first=%s.%ld second=%s.%ld relation=%ld constant=%.1f active=%d",
            phase, guide,
            ItemName(c.firstItem).UTF8String, (long)c.firstAttribute,
            ItemName(c.secondItem).UTF8String, (long)c.secondAttribute,
            (long)c.relation, c.constant, c.active]];
    }
    for (NSString *line in [lines sortedArrayUsingSelector:@selector(compare:)]) {
        printf("%s\n", line.UTF8String);
    }
}

static void LogItem(const char *phase, const char *side, UIBarButtonItem *item) {
    printf("LG_ITEM phase=%s side=%s cls=%s title=%s system=%ld enabled=%d action=%s target=%s id=%s\n",
           phase, side, object_getClassName(item),
           item.title ? item.title.UTF8String : "(nil)",
           (long)item.systemItem, item.enabled,
           SelName(item.action).UTF8String, ItemName(item.target).UTF8String,
           item.accessibilityIdentifier ? item.accessibilityIdentifier.UTF8String : "(nil)");
}

@implementation NavRootViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem *left = self.navigationItem.leftBarButtonItem;
    UIBarButtonItem *right = self.navigationItem.rightBarButtonItem;
    left.accessibilityIdentifier = @"lg.add";
    right.accessibilityIdentifier = @"lg.right";
    LogItem("nib", "left", left);
    LogItem("nib", "right", right);
    printf("LG_ITEM outlet rightItem=%d same=%d\n", self.rightItem != nil, self.rightItem == right);
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.loggedAppear) {
        printf("LG_EVENT root didAppear again\n");
        return;
    }
    self.loggedAppear = YES;
    LogItem("installed", "left", self.navigationItem.leftBarButtonItem);
    LogItem("installed", "right", self.navigationItem.rightBarButtonItem);
    LogGuides(self, "root-nav");

    UINavigationController *nav = self.navigationController;
    [UIView performWithoutAnimation:^{
        nav.navigationBarHidden = YES;
        [nav.view layoutIfNeeded];
    }];
    LogGuides(self, "root-bar-hidden");
    [UIView performWithoutAnimation:^{
        nav.navigationBarHidden = NO;
        [nav.view layoutIfNeeded];
    }];
    LogGuides(self, "root-bar-shown");

    // The NIB ships the right item disabled; enable it for the tap step so the
    // NIB-installed target/action pair is exercised by the XCUITest.
    self.navigationItem.rightBarButtonItem.enabled = YES;
    printf("LG_ITEM phase=enabled side=right enabled=%d\n", self.navigationItem.rightBarButtonItem.enabled);
}
- (IBAction)go:(id)sender {
    printf("LG_EVENT root go\n");
    [self performSegueWithIdentifier:@"toDetail" sender:sender];
}
- (IBAction)plain:(id)sender {
    printf("LG_EVENT root plain\n");
    UIViewController *plain = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"plain"];
    plain.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:plain animated:NO completion:nil];
}
- (IBAction)addTapped:(id)sender {
    printf("LG_EVENT add tapped\n");
    self.stateLabel.text = @"Add tapped";
}
- (IBAction)rightTapped:(id)sender {
    printf("LG_EVENT right tapped\n");
    self.stateLabel.text = @"Right tapped";
}
- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    printf("LG_EVENT root should id=%s\n", identifier.UTF8String);
    return YES;
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    printf("LG_EVENT root prepare id=%s dest=%s\n", segue.identifier.UTF8String,
           object_getClassName(segue.destinationViewController));
    ((NavDetailViewController *)segue.destinationViewController).message = @"from root";
}
@end

@implementation NavDetailViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.detailLabel.text = [NSString stringWithFormat:@"Detail (%@)", self.message];
    printf("LG_EVENT detail viewDidLoad text=%s stack=%lu\n", self.detailLabel.text.UTF8String,
           (unsigned long)self.navigationController.viewControllers.count);
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.loggedAppear) {
        return;
    }
    self.loggedAppear = YES;
    LogGuides(self, "detail-nav");
}
- (IBAction)pop:(id)sender {
    printf("LG_EVENT detail pop\n");
    [self.navigationController popViewControllerAnimated:NO];
}
@end

@implementation PlainViewController
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.loggedAppear) {
        return;
    }
    self.loggedAppear = YES;
    LogGuides(self, "plain-no-nav");
}
- (IBAction)close:(id)sender {
    printf("LG_EVENT plain close\n");
    [self dismissViewControllerAnimated:NO completion:nil];
}
@end
