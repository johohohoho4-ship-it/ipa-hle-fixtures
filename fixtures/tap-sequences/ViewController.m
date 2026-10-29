#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#include <stdio.h>

// A plain UIView that records the raw touch phases delivered to it before the
// gesture recognizers decide. UITapGestureRecognizer has no public per-touch
// tapCount, so the measured UITouch.tapCount is taken from these callbacks.
@interface TapSurfaceView : UIView
@property (nonatomic, copy) NSString *surfaceName;
@property (nonatomic) NSInteger lastTapCount;
@property (nonatomic) CFTimeInterval lastPhaseTime;
@property (nonatomic) CFTimeInterval previousPhaseTime;
@end

@implementation TapSurfaceView

- (void)recordPhase:(NSString *)phase touches:(NSSet<UITouch *> *)touches {
    UITouch *touch = [touches anyObject];
    CFTimeInterval now = CACurrentMediaTime();
    CFTimeInterval deltaMs = self.previousPhaseTime > 0 ? (now - self.previousPhaseTime) * 1000.0 : -1.0;
    self.previousPhaseTime = now;
    self.lastPhaseTime = now;
    self.lastTapCount = touch.tapCount;
    printf("TAP_TOUCH surface=%s phase=%s tapCount=%ld touches=%lu dtMs=%.3f time=%.6f\n",
           self.surfaceName.UTF8String, phase.UTF8String, (long)touch.tapCount,
           (unsigned long)touches.count, deltaMs, now);
    fflush(stdout);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self recordPhase:@"began" touches:touches];
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    // Not recorded: continuous movement would flood the protocol. The tap
    // sequence is fully described by began/ended/cancelled.
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self recordPhase:@"ended" touches:touches];
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self recordPhase:@"cancelled" touches:touches];
    [super touchesCancelled:touches withEvent:event];
}

@end

@interface ViewController ()
@property (nonatomic, strong) TapSurfaceView *singleSurface;
@property (nonatomic, strong) TapSurfaceView *doubleSurface;
@property (nonatomic, strong) TapSurfaceView *twoTapsSurface;
@property (nonatomic, strong) UITapGestureRecognizer *singleRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *doubleRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *deferredSingleRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *twoTapsRecognizer;
@property (nonatomic, strong) UILabel *status;
@property (nonatomic) NSInteger singleCount;
@property (nonatomic) NSInteger doubleCount;
@property (nonatomic) NSInteger deferredCount;
@property (nonatomic) NSInteger twoTapsCount;
@property (nonatomic) CFTimeInterval previousActionTime;
@end

@implementation ViewController

- (TapSurfaceView *)addSurfaceNamed:(NSString *)name
                            caption:(NSString *)captionText
                         identifier:(NSString *)identifier
                              frame:(CGRect)frame
                              color:(UIColor *)color {
    TapSurfaceView *surface = [[TapSurfaceView alloc] initWithFrame:frame];
    surface.surfaceName = name;
    surface.backgroundColor = color;
    surface.accessibilityIdentifier = identifier;
    surface.accessibilityLabel = captionText;
    // An explicit accessibility element keeps the XCUITest lookup on
    // otherElements[identifier] and makes -tap use the surface centre.
    surface.isAccessibilityElement = YES;
    surface.layer.cornerRadius = 8.0;

    UILabel *caption = [[UILabel alloc] initWithFrame:CGRectMake(14, 8, frame.size.width - 28, 20)];
    caption.text = captionText;
    caption.textColor = UIColor.whiteColor;
    caption.font = [UIFont boldSystemFontOfSize:13];
    caption.adjustsFontSizeToFitWidth = YES;
    caption.minimumScaleFactor = 0.6;
    caption.isAccessibilityElement = NO;
    [surface addSubview:caption];

    [self.view addSubview:surface];
    return surface;
}

- (NSString *)statusText {
    return [NSString stringWithFormat:@"single=%ld double=%ld deferred=%ld twotaps=%ld",
            (long)self.singleCount, (long)self.doubleCount,
            (long)self.deferredCount, (long)self.twoTapsCount];
}

- (void)updateStatus {
    self.status.text = [self statusText];
}

- (void)printConfigFor:(UITapGestureRecognizer *)recognizer
                  name:(NSString *)name
               surface:(TapSurfaceView *)surface {
    printf("TAP_CONFIG name=%s surface=%s taps=%lu touches=%lu delaysBegan=%d delaysEnded=%d cancels=%d enabled=%d requiresExclusive=%d state=%ld view=%d gestures=%lu\n",
           name.UTF8String, surface.surfaceName.UTF8String,
           (unsigned long)recognizer.numberOfTapsRequired,
           (unsigned long)recognizer.numberOfTouchesRequired,
           recognizer.delaysTouchesBegan, recognizer.delaysTouchesEnded,
           recognizer.cancelsTouchesInView, recognizer.enabled,
           recognizer.requiresExclusiveTouchType, (long)recognizer.state,
           recognizer.view == surface,
           (unsigned long)surface.gestureRecognizers.count);
    fflush(stdout);
}

- (void)reportAction:(NSString *)name
          recognizer:(UITapGestureRecognizer *)recognizer
             surface:(TapSurfaceView *)surface
               count:(NSInteger)count {
    CFTimeInterval now = CACurrentMediaTime();
    CFTimeInterval actionDeltaMs = self.previousActionTime > 0 ? (now - self.previousActionTime) * 1000.0 : -1.0;
    // Time from the last touch phase the surface saw to this callback. For the
    // require-to-fail single tap this includes the recognizer's failure wait.
    CFTimeInterval touchToActionMs = surface.lastPhaseTime > 0 ? (now - surface.lastPhaseTime) * 1000.0 : -1.0;
    self.previousActionTime = now;
    printf("TAP_ACTION name=%s surface=%s count=%ld tapCount=%ld tapsRequired=%lu touchesRequired=%lu state=%ld dtMs=%.3f touchToActionMs=%.3f time=%.6f\n",
           name.UTF8String, surface.surfaceName.UTF8String, (long)count,
           (long)surface.lastTapCount,
           (unsigned long)recognizer.numberOfTapsRequired,
           (unsigned long)recognizer.numberOfTouchesRequired,
           (long)recognizer.state, actionDeltaMs, touchToActionMs, now);
    fflush(stdout);
    [self updateStatus];
}

- (void)singleTapped:(UITapGestureRecognizer *)sender {
    self.singleCount++;
    [self reportAction:@"single" recognizer:sender surface:self.singleSurface count:self.singleCount];
}

- (void)doubleTapped:(UITapGestureRecognizer *)sender {
    self.doubleCount++;
    [self reportAction:@"double" recognizer:sender surface:self.doubleSurface count:self.doubleCount];
}

- (void)deferredSingleTapped:(UITapGestureRecognizer *)sender {
    self.deferredCount++;
    [self reportAction:@"deferredSingle" recognizer:sender surface:self.doubleSurface count:self.deferredCount];
}

- (void)twoTapsRecognized:(UITapGestureRecognizer *)sender {
    self.twoTapsCount++;
    [self reportAction:@"twoTaps" recognizer:sender surface:self.twoTapsSurface count:self.twoTapsCount];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    CGFloat width = self.view.bounds.size.width;
    CGFloat surfaceWidth = width - 48.0;

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(24, 60, surfaceWidth, 24)];
    title.text = @"Tap Sequences";
    title.font = [UIFont boldSystemFontOfSize:18];
    [self.view addSubview:title];

    self.singleSurface = [self addSurfaceNamed:@"single"
                                      caption:@"single (1 tap)"
                                   identifier:@"surface.single"
                                        frame:CGRectMake(24, 92, surfaceWidth, 78)
                                        color:UIColor.systemBlueColor];
    self.doubleSurface = [self addSurfaceNamed:@"double"
                                      caption:@"double (2 taps) + deferred single"
                                   identifier:@"surface.double"
                                        frame:CGRectMake(24, 180, surfaceWidth, 78)
                                        color:UIColor.systemOrangeColor];
    self.twoTapsSurface = [self addSurfaceNamed:@"twotaps"
                                       caption:@"twotaps (2 taps, no require-to-fail)"
                                    identifier:@"surface.twotaps"
                                         frame:CGRectMake(24, 268, surfaceWidth, 78)
                                         color:UIColor.systemPurpleColor];

    self.singleRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapped:)];
    self.singleRecognizer.numberOfTapsRequired = 1;
    [self.singleSurface addGestureRecognizer:self.singleRecognizer];

    // Measured: a double tap fires only this recognizer.
    self.doubleRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapped:)];
    self.doubleRecognizer.numberOfTapsRequired = 2;
    [self.doubleSurface addGestureRecognizer:self.doubleRecognizer];

    // Measured: a single tap on the same surface waits for the double tap to
    // fail and only then fires.
    self.deferredSingleRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(deferredSingleTapped:)];
    self.deferredSingleRecognizer.numberOfTapsRequired = 1;
    [self.deferredSingleRecognizer requireGestureRecognizerToFail:self.doubleRecognizer];
    [self.doubleSurface addGestureRecognizer:self.deferredSingleRecognizer];

    // Measured: one tap is not enough and no recognizer fires.
    self.twoTapsRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(twoTapsRecognized:)];
    self.twoTapsRecognizer.numberOfTapsRequired = 2;
    [self.twoTapsSurface addGestureRecognizer:self.twoTapsRecognizer];

    self.status = [[UILabel alloc] initWithFrame:CGRectMake(24, 356, surfaceWidth, 44)];
    self.status.accessibilityIdentifier = @"tap.status";
    self.status.numberOfLines = 2;
    self.status.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
    self.status.adjustsFontSizeToFitWidth = YES;
    self.status.minimumScaleFactor = 0.7;
    self.status.text = [self statusText];
    [self.view addSubview:self.status];

    [self printConfigFor:self.singleRecognizer name:@"single" surface:self.singleSurface];
    [self printConfigFor:self.doubleRecognizer name:@"double" surface:self.doubleSurface];
    [self printConfigFor:self.deferredSingleRecognizer name:@"deferredSingle" surface:self.doubleSurface];
    [self printConfigFor:self.twoTapsRecognizer name:@"twoTaps" surface:self.twoTapsSurface];
}

@end
