#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#include <stdio.h>

static BOOL gLoggingEnabled = NO;
static NSInteger gCallbackCount = 0;

static void logTraitCallback(const char *who,
                             UITraitCollection *current,
                             UITraitCollection *previous) {
    if (!gLoggingEnabled) {
        return;
    }
    gCallbackCount += 1;
    NSInteger prevStyle = previous ? previous.userInterfaceStyle : -1;
    NSInteger curStyle = current.userInterfaceStyle;
    BOOL diffColor = [current hasDifferentColorAppearanceComparedToTraitCollection:previous];
    NSInteger threadStyle = UITraitCollection.currentTraitCollection.userInterfaceStyle;
    printf("TCB_CB who=%s prev=%ld cur=%ld diffColor=%d threadStyle=%ld\n",
           who, (long)prevStyle, (long)curStyle, diffColor ? 1 : 0, (long)threadStyle);
}

@interface TCBProbeView : UIView
@property (nonatomic, copy) NSString *probeTag;
@property (nonatomic, strong) UIColor *dynamicBorderColor;
@end

@implementation TCBProbeView

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    logTraitCallback(self.probeTag.UTF8String ?: "view", self.traitCollection, previousTraitCollection);
    if (gLoggingEnabled && self.dynamicBorderColor != nil) {
        CGColorRef cg = self.dynamicBorderColor.CGColor;
        self.layer.borderColor = cg;
        size_t count = cg ? CGColorGetNumberOfComponents(cg) : 0;
        const CGFloat *c = cg ? CGColorGetComponents(cg) : NULL;
        if (c != NULL && count >= 4) {
            printf("TCB_BORDER who=%s rgba=%.3f,%.3f,%.3f,%.3f\n",
                   self.probeTag.UTF8String ?: "view", c[0], c[1], c[2], c[3]);
        }
    }
}
#pragma clang diagnostic pop

@end

@interface TCBChildViewController : UIViewController
@property (nonatomic, copy) NSString *probeTag;
@end

@implementation TCBChildViewController

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    logTraitCallback(self.probeTag.UTF8String ?: "childVC", self.traitCollection, previousTraitCollection);
}
#pragma clang diagnostic pop

@end

@interface ViewController ()
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) TCBProbeView *childView;
@property (nonatomic, strong) TCBProbeView *insulatedView;
@property (nonatomic, strong) TCBChildViewController *childVC;
@property (nonatomic, strong) TCBChildViewController *unloadedVC;
@property (nonatomic, assign) BOOL didRunStartupPhases;
@property (nonatomic, assign) NSInteger toggleStep;
- (void)logProviderAndTraitProfiles;
- (void)toggleAppearance;
- (void)finishToggle;
@end

@implementation ViewController

- (void)loadView {
    TCBProbeView *root = [[TCBProbeView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    root.probeTag = @"rootView";
    self.view = root;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    UIColor *dynamicCard = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traits) {
        if (traits.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return [UIColor colorWithRed:0.90 green:0.20 blue:0.10 alpha:1.0];
        }
        return [UIColor colorWithRed:0.10 green:0.20 blue:0.90 alpha:1.0];
    }];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, 350, 44)];
    title.accessibilityIdentifier = @"tcb.title";
    title.text = @"Trait Callbacks Fixture";
    title.font = [UIFont systemFontOfSize:24 weight:UIFontWeightSemibold];
    title.textColor = UIColor.labelColor;
    [self.view addSubview:title];

    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 160, 350, 40)];
    self.statusLabel.accessibilityIdentifier = @"tcb.status";
    self.statusLabel.text = @"Style: Light (cb=0)";
    self.statusLabel.textColor = UIColor.secondaryLabelColor;
    [self.view addSubview:self.statusLabel];

    UIButton *toggle = [UIButton buttonWithType:UIButtonTypeSystem];
    toggle.frame = CGRectMake(20, 220, 260, 48);
    toggle.accessibilityIdentifier = @"tcb.toggle";
    [toggle setTitle:@"Stil umschalten" forState:UIControlStateNormal];
    [toggle addTarget:self action:@selector(toggleAppearance) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:toggle];

    self.childView = [[TCBProbeView alloc] initWithFrame:CGRectMake(20, 290, 160, 80)];
    self.childView.probeTag = @"childView";
    self.childView.backgroundColor = dynamicCard;
    self.childView.dynamicBorderColor = dynamicCard;
    self.childView.layer.borderWidth = 2.0;
    [self.view addSubview:self.childView];

    self.insulatedView = [[TCBProbeView alloc] initWithFrame:CGRectMake(200, 290, 160, 80)];
    self.insulatedView.probeTag = @"insulatedView";
    self.insulatedView.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    self.insulatedView.backgroundColor = UIColor.secondarySystemBackgroundColor;
    [self.view addSubview:self.insulatedView];

    self.childVC = [[TCBChildViewController alloc] init];
    self.childVC.probeTag = @"childVC";
    TCBProbeView *childVCView = [[TCBProbeView alloc] initWithFrame:CGRectMake(20, 390, 340, 64)];
    childVCView.probeTag = @"childVCView";
    childVCView.backgroundColor = UIColor.tertiarySystemBackgroundColor;
    self.childVC.view = childVCView;
    [self addChildViewController:self.childVC];
    [self.view addSubview:childVCView];
    [self.childVC didMoveToParentViewController:self];

    self.unloadedVC = [[TCBChildViewController alloc] init];
    self.unloadedVC.probeTag = @"unloadedVC";
    [self addChildViewController:self.unloadedVC];
    [self.unloadedVC didMoveToParentViewController:self];

    [self logProviderAndTraitProfiles];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    logTraitCallback("rootVC", self.traitCollection, previousTraitCollection);
}
#pragma clang diagnostic pop

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.didRunStartupPhases) {
        return;
    }
    self.didRunStartupPhases = YES;
    UIWindow *window = self.view.window;
    gLoggingEnabled = YES;

    printf("TCB_PHASE coalesced_noop\n");
    window.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    window.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    [window updateTraitsIfNeeded];
    printf("TCB_MARK after_coalesced_noop cb=%ld\n", (long)gCallbackCount);

    printf("TCB_PHASE sync_dark\n");
    window.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    [window updateTraitsIfNeeded];
    printf("TCB_MARK after_sync_dark cb=%ld\n", (long)gCallbackCount);

    printf("TCB_PHASE sync_light\n");
    window.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    [window updateTraitsIfNeeded];
    printf("TCB_MARK after_sync_light cb=%ld\n", (long)gCallbackCount);

    self.statusLabel.text = [NSString stringWithFormat:@"Style: Light (cb=%ld)", (long)gCallbackCount];
}

- (void)toggleAppearance {
    self.toggleStep += 1;
    UIWindow *window = self.view.window;
    UIUserInterfaceStyle next = (window.overrideUserInterfaceStyle == UIUserInterfaceStyleDark)
        ? UIUserInterfaceStyleLight : UIUserInterfaceStyleDark;
    printf("TCB_PHASE toggle_%ld_to_%s\n",
           (long)self.toggleStep, next == UIUserInterfaceStyleDark ? "dark" : "light");
    window.overrideUserInterfaceStyle = next;
    printf("TCB_MARK after_set_toggle_%ld cb=%ld\n", (long)self.toggleStep, (long)gCallbackCount);
    [self performSelector:@selector(finishToggle) withObject:nil afterDelay:0];
}

- (void)finishToggle {
    NSString *name = (self.view.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) ? @"Dark" : @"Light";
    self.statusLabel.text = [NSString stringWithFormat:@"Style: %@ (cb=%ld)", name, (long)gCallbackCount];
    printf("TCB_MARK after_delay_%ld style=%ld cb=%ld\n",
           (long)self.toggleStep, (long)self.view.traitCollection.userInterfaceStyle, (long)gCallbackCount);
}

- (void)logProviderAndTraitProfiles {
    UITraitCollection *light = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
    UITraitCollection *dark = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];

    __block NSInteger providerCalls = 0;
    UIColor *provider = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traits) {
        providerCalls += 1;
        if (traits.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return [UIColor colorWithRed:0.80 green:0.10 blue:0.20 alpha:1.0];
        }
        return [UIColor colorWithRed:0.10 green:0.60 blue:0.80 alpha:1.0];
    }];
    printf("TCB_PROVIDER create calls=%ld\n", (long)providerCalls);

    CGFloat lr = 0, lg = 0, lb = 0, la = 0;
    CGFloat dr = 0, dg = 0, db = 0, da = 0;
    [[provider resolvedColorWithTraitCollection:light] getRed:&lr green:&lg blue:&lb alpha:&la];
    [[provider resolvedColorWithTraitCollection:dark] getRed:&dr green:&dg blue:&db alpha:&da];
    printf("TCB_PROVIDER resolved light=%.3f,%.3f,%.3f,%.3f dark=%.3f,%.3f,%.3f,%.3f calls=%ld\n",
           lr, lg, lb, la, dr, dg, db, da, (long)providerCalls);

    NSInteger callsBeforeAlpha = providerCalls;
    UIColor *translucent = [provider colorWithAlphaComponent:0.5];
    printf("TCB_PROVIDER alpha_create deltaCalls=%ld\n", (long)(providerCalls - callsBeforeAlpha));
    [[translucent resolvedColorWithTraitCollection:light] getRed:&lr green:&lg blue:&lb alpha:&la];
    [[translucent resolvedColorWithTraitCollection:dark] getRed:&dr green:&dg blue:&db alpha:&da];
    printf("TCB_PROVIDER alpha_resolved light=%.3f,%.3f,%.3f,%.3f dark=%.3f,%.3f,%.3f,%.3f\n",
           lr, lg, lb, la, dr, dg, db, da);

    UIColor *nested = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traits) {
        return UIColor.systemBackgroundColor;
    }];
    [[nested resolvedColorWithTraitCollection:light] getRed:&lr green:&lg blue:&lb alpha:&la];
    [[nested resolvedColorWithTraitCollection:dark] getRed:&dr green:&dg blue:&db alpha:&da];
    printf("TCB_PROVIDER nested light=%.3f,%.3f,%.3f,%.3f dark=%.3f,%.3f,%.3f,%.3f\n",
           lr, lg, lb, la, dr, dg, db, da);

    NSInteger styleBeforePerform = UITraitCollection.currentTraitCollection.userInterfaceStyle;
    [light performAsCurrentTraitCollection:^{
        CGFloat or_ = 0, og = 0, ob = 0, oa = 0;
        [provider getRed:&or_ green:&og blue:&ob alpha:&oa];
        printf("TCB_CURRENT outer style=%ld rgba=%.3f,%.3f,%.3f,%.3f\n",
               (long)UITraitCollection.currentTraitCollection.userInterfaceStyle, or_, og, ob, oa);
        [dark performAsCurrentTraitCollection:^{
            CGFloat ir = 0, ig = 0, ib = 0, ia = 0;
            [provider getRed:&ir green:&ig blue:&ib alpha:&ia];
            CGColorRef cg = provider.CGColor;
            const CGFloat *c = cg ? CGColorGetComponents(cg) : NULL;
            size_t n = cg ? CGColorGetNumberOfComponents(cg) : 0;
            printf("TCB_CURRENT inner style=%ld rgba=%.3f,%.3f,%.3f,%.3f cg=%.3f,%.3f,%.3f,%.3f\n",
                   (long)UITraitCollection.currentTraitCollection.userInterfaceStyle,
                   ir, ig, ib, ia,
                   (c && n >= 4) ? c[0] : -1.0, (c && n >= 4) ? c[1] : -1.0,
                   (c && n >= 4) ? c[2] : -1.0, (c && n >= 4) ? c[3] : -1.0);
        }];
        printf("TCB_CURRENT restored_outer style=%ld\n",
               (long)UITraitCollection.currentTraitCollection.userInterfaceStyle);
    }];
    printf("TCB_CURRENT restored_root same=%d\n",
           UITraitCollection.currentTraitCollection.userInterfaceStyle == styleBeforePerform ? 1 : 0);

    UITraitCollection *regularW = [UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassRegular];
    UITraitCollection *unspecStyle = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleUnspecified];
    UITraitCollection *unspecW = [UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassUnspecified];
    UITraitCollection *empty = [[UITraitCollection alloc] init];
    UITraitCollection *merged = [UITraitCollection traitCollectionWithTraitsFromCollections:@[
        dark, regularW, unspecStyle, unspecW, empty
    ]];
    UITraitCollection *lightRegular = [UITraitCollection traitCollectionWithTraitsFromCollections:@[light, regularW]];
    printf("TCB_TRAIT merge style=%ld h=%ld emptyEqUnspec=%d diffLD=%d diffLLR=%d diffNil=%d\n",
           (long)merged.userInterfaceStyle, (long)merged.horizontalSizeClass,
           [empty isEqual:unspecStyle] ? 1 : 0,
           [light hasDifferentColorAppearanceComparedToTraitCollection:dark] ? 1 : 0,
           [light hasDifferentColorAppearanceComparedToTraitCollection:lightRegular] ? 1 : 0,
           [light hasDifferentColorAppearanceComparedToTraitCollection:nil] ? 1 : 0);

    UIViewController *p = [[UIViewController alloc] init];
    UIViewController *c = [[UIViewController alloc] init];
    UIViewController *g = [[UIViewController alloc] init];
    [p addChildViewController:c];
    [c addChildViewController:g];
    p.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    UITraitCollection *xxl = [UITraitCollection traitCollectionWithPreferredContentSizeCategory:
        UIContentSizeCategoryExtraExtraLarge];
    [p setOverrideTraitCollection:xxl forChildViewController:c];
    UITraitCollection *stored = [p overrideTraitCollectionForChildViewController:c];
    printf("TCB_TRAIT unloaded loaded=%d,%d,%d styles=%ld,%ld,%ld gcCat=%s storedEq=%d\n",
           p.isViewLoaded ? 1 : 0, c.isViewLoaded ? 1 : 0, g.isViewLoaded ? 1 : 0,
           (long)p.traitCollection.userInterfaceStyle,
           (long)c.traitCollection.userInterfaceStyle,
           (long)g.traitCollection.userInterfaceStyle,
           g.traitCollection.preferredContentSizeCategory.UTF8String ?: "",
           [stored isEqual:xxl] ? 1 : 0);
}

@end
