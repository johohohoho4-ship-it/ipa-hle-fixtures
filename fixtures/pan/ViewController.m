#import "ViewController.h"
#include <stdio.h>

@interface RecordingPan : UIPanGestureRecognizer
@end
@implementation RecordingPan
- (void)after:(NSString *)phase {
    CGPoint t = [self translationInView:self.view];
    printf("PAN_AFTER phase=%s state=%ld translation=%.3f,%.3f touches=%lu\n", phase.UTF8String,
        (long)self.state, t.x, t.y, (unsigned long)self.numberOfTouches);
}
- (void)report:(NSString *)phase touches:(NSSet<UITouch *> *)touches {
    UITouch *touch = touches.anyObject; CGPoint p = [touch locationInView:nil];
    printf("PAN_INPUT phase=%s point=%.3f,%.3f time=%.6f\n", phase.UTF8String, p.x, p.y, touch.timestamp);
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self report:@"began" touches:touches]; [super touchesBegan:touches withEvent:event];
    [self after:@"began"];
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self report:@"moved" touches:touches]; [super touchesMoved:touches withEvent:event];
    [self after:@"moved"];
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self report:@"ended" touches:touches]; [super touchesEnded:touches withEvent:event];
    [self after:@"ended"];
}
@end

@interface RawSurface : UIView
@end
@implementation RawSurface
- (void)report:(NSString *)phase touches:(NSSet<UITouch *> *)touches {
    UITouch *touch = touches.anyObject; CGPoint p = [touch locationInView:nil];
    printf("PAN_VIEW phase=%s state=%ld point=%.3f,%.3f\n", phase.UTF8String, (long)touch.phase, p.x, p.y);
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self report:@"began" touches:touches]; }
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self report:@"moved" touches:touches]; }
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self report:@"ended" touches:touches]; }
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self report:@"cancelled" touches:touches]; }
@end

@interface ViewController ()
@property(nonatomic, strong) UILabel *status;
@property(nonatomic, strong) UIPanGestureRecognizer *pan;
@property(nonatomic) NSInteger completed;
@end
@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad]; self.view.backgroundColor = UIColor.whiteColor;
    RawSurface *surface = [[RawSurface alloc] initWithFrame:CGRectMake(40, 110, 220, 240)];
    surface.backgroundColor = UIColor.blueColor; [self.view addSubview:surface];
    self.status = [[UILabel alloc] initWithFrame:CGRectMake(30, 550, 330, 45)];
    self.status.text = @"Ready"; self.status.accessibilityIdentifier = @"pan.status"; [self.view addSubview:self.status];
    self.pan = [[RecordingPan alloc] initWithTarget:self action:@selector(panned:)];
    [surface addGestureRecognizer:self.pan];
    CGPoint p = [self.pan locationInView:surface], t = [self.pan translationInView:surface];
    printf("PAN_CONFIG state=%ld min=%lu max=%lu enabled=%d cancel=%d delayb=%d delaye=%d location=%.3f,%.3f translation=%.3f,%.3f\n",
        (long)self.pan.state, (unsigned long)self.pan.minimumNumberOfTouches, (unsigned long)self.pan.maximumNumberOfTouches,
        self.pan.enabled, self.pan.cancelsTouchesInView, self.pan.delaysTouchesBegan, self.pan.delaysTouchesEnded, p.x, p.y, t.x, t.y);
}
- (void)panned:(UIPanGestureRecognizer *)pan {
    CGPoint p = [pan locationInView:pan.view], t = [pan translationInView:pan.view], w = [pan translationInView:nil];
    printf("PAN_ACTION state=%ld touches=%lu location=%.3f,%.3f translation=%.3f,%.3f window=%.3f,%.3f\n",
        (long)pan.state, (unsigned long)pan.numberOfTouches, p.x, p.y, t.x, t.y, w.x, w.y);
    if (pan.state == UIGestureRecognizerStateBegan && self.completed == 0) {
        [pan setTranslation:CGPointMake(10,-20) inView:pan.view]; t = [pan translationInView:pan.view];
        printf("PAN_SET translation=%.3f,%.3f\n", t.x, t.y);
    }
    if (pan.state == UIGestureRecognizerStateEnded) {
        self.completed++;
        [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(idle:) userInfo:nil repeats:NO];
    }
}
- (void)idle:(NSTimer *)timer {
    CGPoint p = [self.pan locationInView:self.pan.view], t = [self.pan translationInView:self.pan.view];
    printf("PAN_IDLE state=%ld touches=%lu location=%.3f,%.3f translation=%.3f,%.3f\n",
        (long)self.pan.state, (unsigned long)self.pan.numberOfTouches, p.x, p.y, t.x, t.y);
    self.status.text = [NSString stringWithFormat:@"Idle %ld", (long)self.completed];
    if (self.completed == 4) {
        self.pan.cancelsTouchesInView = NO;
        printf("PAN_FLAGS cancel=%d\n", self.pan.cancelsTouchesInView);
    }
}
@end
