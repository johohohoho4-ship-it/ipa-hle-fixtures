#import "ViewControllers.h"
#include <stdio.h>

// F5/B4 reference: a UISplitViewController decoded from Main.storyboard with a master and
// a detail child. The fixture measures only what UIKit returns: the coder profile of the
// split controller, the identity and parent links of its children, the order of the
// lifecycle/appearance/rotation callbacks per phase, and the frames after layout. The
// preferredDisplayMode probe at the end only prints before/after values; it asserts no
// expected mode.

static NSUInteger gGlobalSeq = 0;
static NSMutableDictionary<NSString *, NSNumber *> *gPhaseSeqs = nil;
static NSString *gPhase = @"portrait";
static BOOL gSawLandscape = NO;
static BOOL gDidInitialReport = NO;

static const char *cstr(NSString *value) { return value ? value.UTF8String : "nil"; }

static NSString *rectStr(CGRect r) {
    return [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", r.origin.x, r.origin.y, r.size.width, r.size.height];
}

static NSString *sizeStr(CGSize s) {
    return [NSString stringWithFormat:@"%.3f,%.3f", s.width, s.height];
}

static NSString *className(id object) {
    return object ? [NSString stringWithUTF8String:object_getClassName(object)] : @"none";
}

// The phase is derived from the target size of the transition. A later portrait target is
// "restored"; the very first portrait phase is "portrait".
static NSString *phaseForSize(CGSize size) {
    NSString *phase = size.width > size.height ? @"landscape" : (gSawLandscape ? @"restored" : @"portrait");
    if ([phase isEqualToString:@"landscape"]) {
        gSawLandscape = YES;
    }
    if (![phase isEqualToString:gPhase]) {
        gPhase = phase;
        printf("SPV_PHASE name=%s size=%s\n", cstr(phase), sizeStr(size).UTF8String);
        fflush(stdout);
    }
    return phase;
}

static void logCallback(NSString *phase, NSString *owner, NSString *event, NSString *detail) {
    if (!gPhaseSeqs) {
        gPhaseSeqs = [NSMutableDictionary dictionary];
    }
    NSUInteger seq = gPhaseSeqs[phase].unsignedIntegerValue + 1;
    gPhaseSeqs[phase] = @(seq);
    printf("SPV_CB phase=%s seq=%lu global=%lu owner=%s event=%s%s%s\n",
           cstr(phase), (unsigned long)seq, (unsigned long)++gGlobalSeq, cstr(owner), cstr(event),
           detail.length ? " " : "", detail.length ? detail.UTF8String : "");
    fflush(stdout);
}

// storyboardIdentifier is read through KVC so the line reports "unavailable" instead of
// guessing if the running UIKit does not expose that key.
static NSString *storyboardIdentifier(UIViewController *controller) {
    @try {
        id value = [controller valueForKey:@"storyboardIdentifier"];
        return value ? [value description] : @"nil";
    } @catch (NSException *exception) {
        return @"unavailable";
    }
}

@interface SPVSplitViewController ()
- (void)spvPrintProfile:(NSString *)phase;
- (void)spvPrintIdentity:(NSString *)phase;
- (void)spvPrintGeometry:(NSString *)phase;
- (void)spvSetStatus:(NSString *)text;
- (void)spvProbePreferredDisplayMode;
@end

@implementation SPVSplitViewController

#pragma mark - measurements

- (void)spvPrintProfile:(NSString *)phase {
    printf("SPV_ARCH phase=%s displayMode=%ld preferredDisplayMode=%ld preferredMatchesDisplay=%d primaryEdge=%ld presentsWithGesture=%d collapsed=%d viewControllers=%lu delegate=%d delegateClass=%s\n",
           cstr(phase), (long)self.displayMode, (long)self.preferredDisplayMode,
           self.displayMode == self.preferredDisplayMode, (long)self.primaryEdge,
           self.presentsWithGesture, self.collapsed, (unsigned long)self.viewControllers.count,
           self.delegate != nil, cstr(className(self.delegate)));
}

- (void)spvPrintIdentity:(NSString *)phase {
    BOOL containsMaster = NO;
    BOOL containsDetail = NO;
    for (UIViewController *controller in self.viewControllers) {
        if ([controller isKindOfClass:[SPVMasterViewController class]]) containsMaster = YES;
        if ([controller isKindOfClass:[SPVDetailViewController class]]) containsDetail = YES;
    }
    printf("SPV_IDENT phase=%s splitClass=%s splitStoryboardIdentifier=%s splitParent=%s splitViewWindow=%d windowClass=%s childCount=%lu containsMaster=%d containsDetail=%d\n",
           cstr(phase), object_getClassName(self), cstr(storyboardIdentifier(self)),
           cstr(className(self.parentViewController)), self.view.window != nil,
           cstr(className(self.view.window)), (unsigned long)self.viewControllers.count,
           containsMaster, containsDetail);
    NSUInteger index = 0;
    for (UIViewController *controller in self.viewControllers) {
        printf("SPV_CHILD phase=%s index=%lu class=%s storyboardIdentifier=%s restorationIdentifier=%s parentClass=%s parentIsSplit=%d viewLoaded=%d viewSuperview=%s\n",
               cstr(phase), (unsigned long)index++, object_getClassName(controller),
               cstr(storyboardIdentifier(controller)), cstr(controller.restorationIdentifier),
               cstr(className(controller.parentViewController)), controller.parentViewController == self,
               controller.isViewLoaded,
               cstr(className(controller.isViewLoaded ? controller.view.superview : nil)));
    }
}

- (void)spvPrintGeometry:(NSString *)phase {
    printf("SPV_GEO phase=%s view=split splitFrame=%s splitBounds=%s splitWindow=%d\n",
           cstr(phase), rectStr(self.view.frame).UTF8String, rectStr(self.view.bounds).UTF8String,
           self.view.window != nil);
    NSUInteger index = 0;
    for (UIViewController *controller in self.viewControllers) {
        if (!controller.isViewLoaded) {
            printf("SPV_GEO phase=%s index=%lu class=%s viewLoaded=0\n",
                   cstr(phase), (unsigned long)index++, object_getClassName(controller));
            continue;
        }
        UIView *view = controller.view;
        printf("SPV_GEO phase=%s index=%lu class=%s viewLoaded=1 viewFrame=%s viewBounds=%s hidden=%d alpha=%.3f window=%d superview=%s\n",
               cstr(phase), (unsigned long)index++, object_getClassName(controller),
               rectStr(view.frame).UTF8String, rectStr(view.bounds).UTF8String, view.hidden,
               view.alpha, view.window != nil, cstr(className(view.superview)));
    }
}

- (void)spvSetStatus:(NSString *)text {
    for (UIViewController *controller in self.viewControllers) {
        if ([controller isKindOfClass:[SPVMasterViewController class]]) {
            [(SPVMasterViewController *)controller setStatusText:text];
            return;
        }
    }
    printf("SPV_STATUS text=%s target=missing\n", cstr(text));
}

- (void)spvProbePreferredDisplayMode {
    UISplitViewControllerDisplayMode preferredBefore = self.preferredDisplayMode;
    UISplitViewControllerDisplayMode displayBefore = self.displayMode;
    BOOL collapsedBefore = self.collapsed;
    self.preferredDisplayMode = UISplitViewControllerDisplayModeOneBesideSecondary;
    printf("SPV_PREF phase=restored probe=set-one-beside-secondary preferredBefore=%ld displayBefore=%ld matchesBefore=%d collapsedBefore=%d preferredAfter=%ld displayAfter=%ld collapsedAfter=%d\n",
           (long)preferredBefore, (long)displayBefore, preferredBefore == displayBefore,
           collapsedBefore, (long)self.preferredDisplayMode, (long)self.displayMode,
           self.collapsed);
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    printf("SPV_PREF phase=restored probe=after-layout preferred=%ld display=%ld matches=%d collapsed=%d viewControllers=%lu\n",
           (long)self.preferredDisplayMode, (long)self.displayMode,
           self.preferredDisplayMode == self.displayMode, self.collapsed,
           (unsigned long)self.viewControllers.count);
}

#pragma mark - lifecycle

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        logCallback(gPhase, @"SPVSplitViewController", @"initWithCoder", nil);
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    logCallback(gPhase, @"SPVSplitViewController", @"awakeFromNib",
                [NSString stringWithFormat:@"viewLoaded=%d viewControllers=%lu",
                 self.isViewLoaded, (unsigned long)self.viewControllers.count]);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    logCallback(gPhase, @"SPVSplitViewController", @"viewDidLoad", nil);
    [self spvPrintProfile:@"didload"];
    [self spvPrintIdentity:@"didload"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    logCallback(gPhase, @"SPVSplitViewController", @"viewWillAppear",
                [NSString stringWithFormat:@"presented=%d", self.isBeingPresented]);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    logCallback(gPhase, @"SPVSplitViewController", @"viewDidAppear", nil);
    [self spvPrintProfile:@"appear"];
    [self spvPrintIdentity:@"appear"];
    [self spvPrintGeometry:@"appear"];
    if (!gDidInitialReport) {
        gDidInitialReport = YES;
        [self spvSetStatus:@"READY"];
        printf("SPV_READY phase=%s viewControllers=%lu collapsed=%d displayMode=%ld\n",
               cstr(gPhase), (unsigned long)self.viewControllers.count, self.collapsed,
               (long)self.displayMode);
    }
}

#pragma mark - rotation

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    NSString *phase = phaseForSize(size);
    logCallback(phase, @"SPVSplitViewController", @"viewWillTransitionToSize",
                [NSString stringWithFormat:@"target=%s collapsed=%d displayMode=%ld viewControllers=%lu",
                 sizeStr(size).UTF8String, self.collapsed, (long)self.displayMode,
                 (unsigned long)self.viewControllers.count]);
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    __weak SPVSplitViewController *weakSelf = self;
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        SPVSplitViewController *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        NSString *donePhase = gPhase;
        logCallback(donePhase, @"SPVSplitViewController", @"transitionCompletion",
                    [NSString stringWithFormat:@"completed=%d cancelled=%d duration=%.3f",
                     context.completed, context.cancelled, context.transitionDuration]);
        [strongSelf spvPrintProfile:donePhase];
        [strongSelf spvPrintIdentity:donePhase];
        [strongSelf spvPrintGeometry:donePhase];
        if ([donePhase isEqualToString:@"landscape"]) {
            if (!gDidInitialReport) {
                // A size transition before the first viewDidAppear is not the test rotation.
                printf("SPV_ROTATION ignored=before-ready phase=%s\n", cstr(donePhase));
                return;
            }
            [strongSelf spvSetStatus:@"LANDSCAPE"];
            printf("SPV_LANDSCAPE phase=%s splitFrame=%s splitBounds=%s collapsed=%d displayMode=%ld\n",
                   cstr(donePhase), rectStr(strongSelf.view.frame).UTF8String,
                   rectStr(strongSelf.view.bounds).UTF8String, strongSelf.collapsed,
                   (long)strongSelf.displayMode);
        } else if ([donePhase isEqualToString:@"restored"]) {
            // The probe mutates preferredDisplayMode; the final status text is set after it so
            // the XCUITest still reads the label that belongs to the completed rotation.
            [strongSelf spvProbePreferredDisplayMode];
            [strongSelf spvSetStatus:@"PORTRAIT"];
            printf("SPV_PORTRAIT phase=%s splitFrame=%s splitBounds=%s collapsed=%d displayMode=%ld\n",
                   cstr(donePhase), rectStr(strongSelf.view.frame).UTF8String,
                   rectStr(strongSelf.view.bounds).UTF8String, strongSelf.collapsed,
                   (long)strongSelf.displayMode);
        } else {
            // An initial portrait resize is only recorded; READY/PORTRAIT belong to the test flow.
            printf("SPV_ROTATION ignored=initial-portrait phase=%s\n", cstr(donePhase));
        }
    }];
}

@end

@implementation SPVMasterViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        logCallback(gPhase, @"SPVMasterViewController", @"initWithCoder", nil);
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    logCallback(gPhase, @"SPVMasterViewController", @"awakeFromNib",
                [NSString stringWithFormat:@"viewLoaded=%d", self.isViewLoaded]);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    logCallback(gPhase, @"SPVMasterViewController", @"viewDidLoad",
                [NSString stringWithFormat:@"statusLabel=%s identifier=%s",
                 cstr(className(self.statusLabel)), cstr(self.statusLabel.accessibilityIdentifier)]);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    logCallback(gPhase, @"SPVMasterViewController", @"viewWillAppear", nil);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    logCallback(gPhase, @"SPVMasterViewController", @"viewDidAppear",
                [NSString stringWithFormat:@"viewFrame=%s viewWindow=%d status=%s",
                 rectStr(self.view.frame).UTF8String, self.view.window != nil,
                 cstr(self.statusLabel.text)]);
}

- (void)setStatusText:(NSString *)text {
    BOOL forcedLoad = NO;
    if (!self.isViewLoaded) {
        // Only if UIKit has not loaded the master yet; recorded instead of silently waiting.
        [self loadViewIfNeeded];
        forcedLoad = YES;
    }
    self.statusLabel.text = text;
    printf("SPV_STATUS text=%s owner=master forcedLoad=%d labelIdentifier=%s labelFrame=%s labelWindow=%d\n",
           cstr(text), forcedLoad, cstr(self.statusLabel.accessibilityIdentifier),
           rectStr(self.statusLabel.frame).UTF8String, self.statusLabel.window != nil);
    fflush(stdout);
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    NSString *phase = phaseForSize(size);
    logCallback(phase, @"SPVMasterViewController", @"viewWillTransitionToSize",
                [NSString stringWithFormat:@"target=%s", sizeStr(size).UTF8String]);
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        logCallback(gPhase, @"SPVMasterViewController", @"transitionCompletion",
                    [NSString stringWithFormat:@"completed=%d viewFrame=%s viewWindow=%d",
                     context.completed, rectStr(self.view.frame).UTF8String,
                     self.view.window != nil]);
    }];
}

@end

@implementation SPVDetailViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        logCallback(gPhase, @"SPVDetailViewController", @"initWithCoder", nil);
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    logCallback(gPhase, @"SPVDetailViewController", @"awakeFromNib",
                [NSString stringWithFormat:@"viewLoaded=%d", self.isViewLoaded]);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    logCallback(gPhase, @"SPVDetailViewController", @"viewDidLoad",
                [NSString stringWithFormat:@"viewFrame=%s viewBounds=%s",
                 rectStr(self.view.frame).UTF8String, rectStr(self.view.bounds).UTF8String]);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    logCallback(gPhase, @"SPVDetailViewController", @"viewWillAppear", nil);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    logCallback(gPhase, @"SPVDetailViewController", @"viewDidAppear",
                [NSString stringWithFormat:@"viewFrame=%s viewWindow=%d",
                 rectStr(self.view.frame).UTF8String, self.view.window != nil]);
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    NSString *phase = phaseForSize(size);
    logCallback(phase, @"SPVDetailViewController", @"viewWillTransitionToSize",
                [NSString stringWithFormat:@"target=%s", sizeStr(size).UTF8String]);
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        logCallback(gPhase, @"SPVDetailViewController", @"transitionCompletion",
                    [NSString stringWithFormat:@"completed=%d viewFrame=%s viewWindow=%d",
                     context.completed, rectStr(self.view.frame).UTF8String,
                     self.view.window != nil]);
    }];
}

@end
