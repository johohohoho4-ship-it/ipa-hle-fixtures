#import "ViewController.h"
#include <stdio.h>

static void PrintRect(const char *phase, const char *name, CGRect rect) {
    printf("WS_RECT phase=%s name=%s x=%.1f y=%.1f w=%.1f h=%.1f\n", phase, name,
           rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

@interface ViewController ()
@property(nonatomic, strong) UILabel *stateLabel;
@property(nonatomic, strong) UIWindow *sceneWindowProbe;
@property(nonatomic, strong) UIWindow *frameWindowProbe;
@property(nonatomic) NSUInteger sample;
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.stateLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, 600, 70)];
    self.stateLabel.accessibilityIdentifier = @"ws.state";
    self.stateLabel.text = @"waiting";
    [self.view addSubview:self.stateLabel];
}

- (void)recordGeometry {
    UIWindow *window = self.view.window;
    UIWindowScene *scene = window.windowScene;
    BOOL landscape = UIInterfaceOrientationIsLandscape(scene.interfaceOrientation);
    const char *phase = self.sample == 0 ? "portrait" : self.sample == 1 ? "landscape" : "restored";
    id<UICoordinateSpace> space = scene.coordinateSpace;
    UIScreen *screen = scene.screen;
    BOOL expectedOrientation = self.sample == 1 ? landscape : scene.interfaceOrientation == UIInterfaceOrientationPortrait;
    if (!scene || self.sample > 2 || !expectedOrientation) {
        // Initial orientation is established by XCUITest before launch.
        self.stateLabel.text = @"unexpected-scene";
        return;
    }
    printf("WS_SCENE phase=%s role=%s orientation=%ld stableSpace=%d spaceIsScene=%d scale=%.1f\n",
           phase, scene.session.role.UTF8String, (long)scene.interfaceOrientation,
           space == scene.coordinateSpace, (id)space == scene, screen.scale);
    PrintRect(phase, "scene", space.bounds);
    PrintRect(phase, "screen", screen.bounds);
    PrintRect(phase, "screenFixed", screen.fixedCoordinateSpace.bounds);
    PrintRect(phase, "windowFrame", window.frame);
    PrintRect(phase, "windowBounds", window.bounds);
    if (self.sample == 0) {
        // Neither probe becomes key/visible. Observe constructor/setter behavior
        // without replacing the actual scene delegate's window.
        self.sceneWindowProbe = [[UIWindow alloc] initWithWindowScene:scene];
        self.frameWindowProbe = [[UIWindow alloc] initWithFrame:CGRectMake(7, 11, 123, 234)];
        printf("WS_BIND phase=portrait initScene=%d frameInitiallyNil=%d\n",
               self.sceneWindowProbe.windowScene == scene, self.frameWindowProbe.windowScene == nil);
        PrintRect(phase, "initSceneFrame", self.sceneWindowProbe.frame);
        self.frameWindowProbe.windowScene = scene;
        printf("WS_BIND phase=portrait afterSet=%d\n", self.frameWindowProbe.windowScene == scene);
        printf("WS_MEMBERS phase=afterSet sceneHasFrame=%d appHasFrame=%d sceneHasInit=%d appHasInit=%d\n",
               [scene.windows containsObject:self.frameWindowProbe],
               [UIApplication.sharedApplication.windows containsObject:self.frameWindowProbe],
               [scene.windows containsObject:self.sceneWindowProbe],
               [UIApplication.sharedApplication.windows containsObject:self.sceneWindowProbe]);
        PrintRect(phase, "afterSetFrame", self.frameWindowProbe.frame);
        self.frameWindowProbe.windowScene = nil;
        printf("WS_BIND phase=portrait afterClearNil=%d\n", self.frameWindowProbe.windowScene == nil);
        printf("WS_MEMBERS phase=afterClear sceneHasFrame=%d appHasFrame=%d sceneHasInit=%d appHasInit=%d\n",
               [scene.windows containsObject:self.frameWindowProbe],
               [UIApplication.sharedApplication.windows containsObject:self.frameWindowProbe],
               [scene.windows containsObject:self.sceneWindowProbe],
               [UIApplication.sharedApplication.windows containsObject:self.sceneWindowProbe]);
        PrintRect(phase, "afterClearFrame", self.frameWindowProbe.frame);
    } else {
        printf("WS_BIND phase=%s initStillAssigned=%d frameStillNil=%d\n", phase,
               self.sceneWindowProbe.windowScene == scene, self.frameWindowProbe.windowScene == nil);
        PrintRect(phase, "initSceneFrame", self.sceneWindowProbe.frame);
    }
    self.sample += 1;
    self.stateLabel.text = [NSString stringWithFormat:@"%s-ready", phase];
    printf("WS_DONE phase=%s\n", phase);
    fflush(stdout);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.sample == 0) [self recordGeometry];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self recordGeometry];
    }];
}
@end
