#import "ViewController.h"
#include <stdio.h>

@interface LoggedController : UIViewController
- (const char *)eventName;
@end
@implementation LoggedController
- (const char *)eventName { return "root"; }
- (void)viewDidLoad { [super viewDidLoad]; printf("VC_EVENT %s load\n", self.eventName); }
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a]; printf("VC_EVENT %s willAppear %d\n", self.eventName, a); }
- (void)viewDidAppear:(BOOL)a { [super viewDidAppear:a]; printf("VC_EVENT %s didAppear %d\n", self.eventName, a); }
- (void)viewIsAppearing:(BOOL)a { [super viewIsAppearing:a]; printf("VC_EVENT %s isAppearing %d\n", self.eventName, a); }
- (void)viewWillLayoutSubviews { [super viewWillLayoutSubviews]; printf("VC_LAYOUT %s willLayout\n", self.eventName); }
- (void)viewDidLayoutSubviews { [super viewDidLayoutSubviews]; printf("VC_LAYOUT %s didLayout\n", self.eventName); }
- (void)viewWillDisappear:(BOOL)a { [super viewWillDisappear:a]; printf("VC_EVENT %s willDisappear %d\n", self.eventName, a); }
- (void)viewDidDisappear:(BOOL)a { [super viewDidDisappear:a]; printf("VC_EVENT %s didDisappear %d\n", self.eventName, a); }
- (void)willMoveToParentViewController:(UIViewController *)parent { [super willMoveToParentViewController:parent]; printf("VC_EVENT %s willMove %d\n", self.eventName, parent != nil); }
- (void)didMoveToParentViewController:(UIViewController *)parent { [super didMoveToParentViewController:parent]; printf("VC_EVENT %s didMove %d\n", self.eventName, parent != nil); }
@end

@interface ChildController : LoggedController
@end
@implementation ChildController
- (const char *)eventName { return "child"; }
- (void)viewDidLoad {
    [super viewDidLoad];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 250, 35)];
    label.text = @"Contained child";
    label.accessibilityIdentifier = @"vc.child";
    [self.view addSubview:label];
}
@end

static UIButton *MakeButton(UIView *view, NSString *title, NSString *identifier, CGFloat y, id target, SEL action) {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(30, y, 290, 48);
    [button setTitle:title forState:UIControlStateNormal];
    button.accessibilityIdentifier = identifier;
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:target action:@selector(afterAction:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:button];
    return button;
}

@interface ModalController : LoggedController
@end
@implementation ModalController
- (const char *)eventName { return self.modalPresentationStyle == UIModalPresentationOverFullScreen ? "overlay" : "modal"; }
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(30, 100, 290, 48)];
    label.text = @"Presented controller";
    label.accessibilityIdentifier = @"vc.modal";
    [self.view addSubview:label];
    MakeButton(self.view, @"Dismiss", @"vc.dismiss", 170, self, @selector(close:));
}
- (void)close:(id)sender {
    printf("VC_BOUNDARY dismiss enter presented=%d\n", self.presentingViewController != nil);
    [self dismissViewControllerAnimated:NO completion:^{ printf("VC_EVENT dismiss completion\n"); }];
    printf("VC_BOUNDARY dismiss return presented=%d dismissing=%d\n", self.presentingViewController != nil, self.isBeingDismissed);
}
- (void)afterAction:(id)sender { printf("VC_BOUNDARY dismiss afterAction\n"); }
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    CGRect r = [self.view convertRect:self.view.bounds toView:self.view.window];
    CGRect w = self.view.window.bounds;
    printf("VC_GEOMETRY %ld %.3f %.3f %.3f %.3f window %.3f %.3f\n", (long)self.modalPresentationStyle,
           r.origin.x, r.origin.y, r.size.width, r.size.height, w.size.width, w.size.height);
    UIEdgeInsets safe = self.view.window.safeAreaInsets;
    printf("VC_SAFE %.3f %.3f %.3f %.3f\n", safe.top, safe.left, safe.bottom, safe.right);
    UIView *source = self.presentingViewController.view;
    CGRect s = [source convertRect:source.bounds toView:self.view.window];
    printf("VC_PRESENTER %.3f %.3f %.3f %.3f\n", s.origin.x, s.origin.y, s.size.width, s.size.height);
}
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    printf("VC_EVENT root load\n");
    self.view.backgroundColor = [UIColor whiteColor];
    MakeButton(self.view, @"Present full screen", @"vc.fullscreen", 100, self, @selector(presentFull:));
    MakeButton(self.view, @"Present overlay", @"vc.overlay", 160, self, @selector(presentOverlay:));
    MakeButton(self.view, @"Present automatic", @"vc.automatic", 340, self, @selector(presentAutomatic:));
    MakeButton(self.view, @"Present page sheet", @"vc.pagesheet", 400, self, @selector(presentPage:));
    MakeButton(self.view, @"Present form sheet", @"vc.formsheet", 460, self, @selector(presentForm:));
    MakeButton(self.view, @"Present popover", @"vc.popover", 520, self, @selector(presentPopover:));
    ChildController *child = [[ChildController alloc] init];
    [self addChildViewController:child];
    child.view.frame = CGRectMake(30, 240, 290, 60);
    [self.view addSubview:child.view];
    [child didMoveToParentViewController:self];
}
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a]; printf("VC_EVENT root willAppear %d\n", a); }
- (void)viewDidAppear:(BOOL)a { [super viewDidAppear:a]; printf("VC_EVENT root didAppear %d\n", a); }
- (void)viewIsAppearing:(BOOL)a { [super viewIsAppearing:a]; printf("VC_EVENT root isAppearing %d\n", a); }
- (void)viewWillLayoutSubviews { [super viewWillLayoutSubviews]; printf("VC_LAYOUT root willLayout\n"); }
- (void)viewDidLayoutSubviews { [super viewDidLayoutSubviews]; printf("VC_LAYOUT root didLayout\n"); }
- (void)viewWillDisappear:(BOOL)a { [super viewWillDisappear:a]; printf("VC_EVENT root willDisappear %d\n", a); }
- (void)viewDidDisappear:(BOOL)a { [super viewDidDisappear:a]; printf("VC_EVENT root didDisappear %d\n", a); }
- (void)presentFull:(id)sender { [self showStyle:UIModalPresentationFullScreen]; }
- (void)presentOverlay:(id)sender { [self showStyle:UIModalPresentationOverFullScreen]; }
- (void)presentAutomatic:(id)sender { [self showStyle:UIModalPresentationAutomatic]; }
- (void)presentPage:(id)sender { [self showStyle:UIModalPresentationPageSheet]; }
- (void)presentForm:(id)sender { [self showStyle:UIModalPresentationFormSheet]; }
- (void)presentPopover:(id)sender { [self showStyle:UIModalPresentationPopover]; }
- (void)showStyle:(UIModalPresentationStyle)style {
    printf("VC_BOUNDARY present enter\n");
    ModalController *vc = [[ModalController alloc] init];
    vc.modalPresentationStyle = style;
    UIPresentationController *pc = vc.presentationController;
    pc.delegate = (id<UIAdaptivePresentationControllerDelegate>)self;
    printf("VC_PC %d %d\n", pc != nil, pc.delegate == self);
    if (style == UIModalPresentationPopover) {
        vc.popoverPresentationController.sourceView = self.view;
        vc.popoverPresentationController.sourceRect = CGRectMake(175, 540, 1, 1);
    }
    [self presentViewController:vc animated:NO completion:^{ printf("VC_EVENT present completion\n"); }];
    printf("VC_BOUNDARY present return loaded=%d presented=%d presenting=%d\n", vc.isViewLoaded, self.presentedViewController == vc, vc.isBeingPresented);
}
- (void)afterAction:(id)sender { printf("VC_BOUNDARY present afterAction\n"); }
@end
