#import "ViewControllers.h"
#import <objc/runtime.h>
#include <stdio.h>

@implementation GuideArchiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.statusLabel.accessibilityIdentifier = @"ga.status";
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.text = @"measuring";
}

- (void)report:(NSString *)phase {
    UILayoutGuide *top = (UILayoutGuide *)self.topLayoutGuide;
    UILayoutGuide *bottom = (UILayoutGuide *)self.bottomLayoutGuide;
    UIView *view = self.view;
    printf("GA_GUIDE phase=%s top=%.1f bottom=%.1f topClass=%s bottomClass=%s distinct=%d "
           "topOwner=%s bottomOwner=%s topFrame=%.1f,%.1f,%.1f,%.1f bottomFrame=%.1f,%.1f,%.1f,%.1f\n",
           phase.UTF8String, top.length, bottom.length, object_getClassName(top), object_getClassName(bottom),
           top != bottom,
           top.owningView ? object_getClassName(top.owningView) : "none",
           bottom.owningView ? object_getClassName(bottom.owningView) : "none",
           top.layoutFrame.origin.x, top.layoutFrame.origin.y, top.layoutFrame.size.width, top.layoutFrame.size.height,
           bottom.layoutFrame.origin.x, bottom.layoutFrame.origin.y, bottom.layoutFrame.size.width,
           bottom.layoutFrame.size.height);
    printf("GA_IDENTITY phase=%s topProperty=1 bottomProperty=1 topIsSafe=%d bottomIsSafe=%d "
           "topOwnerIsView=%d bottomOwnerIsView=%d\n",
           phase.UTF8String, top == (UILayoutGuide *)view.safeAreaLayoutGuide,
           bottom == (UILayoutGuide *)view.safeAreaLayoutGuide,
           top.owningView == view, bottom.owningView == view);
    for (NSLayoutConstraint *constraint in view.constraints) {
        id first = constraint.firstItem;
        id second = constraint.secondItem;
        if (first != top && second != top && first != bottom && second != bottom) {
            continue;
        }
        printf("GA_CONSTRAINT phase=%s first=%s.%ld second=%s.%ld relation=%ld constant=%.1f "
               "priority=%.1f active=%d\n",
               phase.UTF8String,
               first ? object_getClassName(first) : "none", (long)constraint.firstAttribute,
               second ? object_getClassName(second) : "none", (long)constraint.secondAttribute,
               (long)constraint.relation, constraint.constant, constraint.priority, constraint.active);
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.phaseOverride.length) {
        [self report:self.phaseOverride];
        printf("GA_DONE\n");
        self.statusLabel.text = @"GA_DONE";
        return;
    }
    if (self.didRun) {
        return;
    }
    self.didRun = YES;
    [self report:@"nav"];
    self.navigationController.navigationBarHidden = YES;
    [self report:@"bar-hidden"];
    GuideArchiveViewController *plain =
        [self.storyboard instantiateViewControllerWithIdentifier:@"plain"];
    plain.phaseOverride = @"plain";
    [self presentViewController:plain animated:NO completion:nil];
}

@end
