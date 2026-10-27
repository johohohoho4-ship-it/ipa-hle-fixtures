#import "ViewControllers.h"
#include <stdio.h>

static void log_geometry(const char *event, UIViewController *vc) {
    if (!vc.isViewLoaded) {
        printf("GEOM_%s loaded=0\n", event);
        return;
    }
    UIView *view = vc.view;
    CGRect bounds = view.bounds;
    CGRect frame = view.frame;
    printf("GEOM_%s loaded=1 bounds=%.1f,%.1f,%.1f,%.1f frame=%.1f,%.1f,%.1f,%.1f window=%d\n",
           event, bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height,
           frame.origin.x, frame.origin.y, frame.size.width, frame.size.height, view.window != nil);
}

@implementation RootGeometryViewController

- (void)loadView {
    printf("GEOM_LOADVIEW_ENTER mode=%s access=%s loaded=%d\n",
           self.geomMode.UTF8String, self.geomAccess.UTF8String, self.isViewLoaded);
    [super loadView];
    log_geometry("LOADVIEW_EXIT", self);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    log_geometry("VIEWDIDLOAD", self);
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 260, 30)];
    label.accessibilityIdentifier = @"geom.status";
    label.text = @"running";
    [self.view addSubview:label];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    log_geometry("VIEWWILLAPPEAR", self);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    log_geometry("VIEWDIDLAYOUTSUBVIEWS", self);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    log_geometry("VIEWDIDAPPEAR", self);
    for (UIView *view in self.view.subviews) {
        if ([view isKindOfClass:[UILabel class]]) {
            ((UILabel *)view).text = @"GEOM_DONE";
        }
    }
    printf("GEOM_DONE mode=%s access=%s\n", self.geomMode.UTF8String, self.geomAccess.UTF8String);
}

@end
