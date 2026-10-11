#import "ViewController.h"
@import QuartzCore;
#include <stdio.h>

@interface ViewController ()
@property(nonatomic, strong) UIView *square;
@property(nonatomic, strong) UILabel *status;
@property(nonatomic, strong) CADisplayLink *link;
@property(nonatomic) CFTimeInterval startTime;
@property(nonatomic) CFTimeInterval pausedTime;
@property(nonatomic) CFTimeInterval pauseWallTime;
@property(nonatomic) NSInteger phase;
@property(nonatomic) NSInteger bucket;
@end
@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.square = [[UIView alloc] initWithFrame:CGRectMake(40, 110, 120, 120)];
    self.square.backgroundColor = UIColor.blueColor;
    [self.view addSubview:self.square];
    self.status = [[UILabel alloc] initWithFrame:CGRectMake(30, 250, 330, 40)];
    self.status.accessibilityIdentifier = @"ca.status";
    [self.view addSubview:self.status];
    NSArray *titles = @[@"Resume", @"Remove", @"Unwatched"];
    SEL actions[] = {@selector(resume:), @selector(remove:), @selector(unwatched:)};
    for (NSInteger i=0; i<3; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectMake(30, 310 + i*60, 200, 44);
        [button setTitle:titles[i] forState:UIControlStateNormal];
        button.accessibilityIdentifier = [NSString stringWithFormat:@"ca.step%ld", (long)i+1];
        [button addTarget:self action:actions[i] forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    }
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.square.layer.opacity = 0.8;
    [CATransaction commit];
    self.bucket = -1;
}
- (void)install:(CFTimeInterval)duration {
    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.fromValue = @0.2;
    fade.toValue = @1.0;
    fade.duration = duration;
    fade.beginTime = self.startTime;
    fade.timingFunction = [CAMediaTimingFunction functionWithName:@"linear"];
    fade.removedOnCompletion = NO;
    fade.fillMode = @"both";
    [self.square.layer addAnimation:fade forKey:@"fade"];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.startTime = CACurrentMediaTime() + 0.25;
    [self install:2];
    self.status.text = @"Running";
    self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
    [self.link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    printf("CA_RUN_START\n");
}
- (void)tick:(CADisplayLink *)link {
    CFTimeInterval now = CACurrentMediaTime();
    CFTimeInterval local = self.phase == 1 ? self.pausedTime : now - self.square.layer.beginTime;
    CFTimeInterval elapsed = local - self.startTime;
    NSInteger bucket = (NSInteger)(elapsed * 4);
    if ((self.phase == 0 || self.phase == 2) && elapsed >= 0 && bucket != self.bucket) {
        self.bucket = bucket;
        float presented = self.square.layer.presentationLayer.opacity;
        CFTimeInterval after = CACurrentMediaTime() - self.square.layer.beginTime - self.startTime;
        printf("CA_RUN phase=%ld elapsed=%.6f after=%.6f presentation=%.6f model=%.3f\n", (long)self.phase,
            elapsed, after, presented, self.square.layer.opacity);
    }
    if (self.phase == 0 && elapsed >= 0.75) {
        self.pausedTime = local;
        self.pauseWallTime = now;
        self.square.layer.speed = 0;
        self.square.layer.timeOffset = local;
        self.phase = 1;
        printf("CA_PAUSE elapsed=%.6f\n", elapsed);
    } else if (self.phase == 1 && now - self.pauseWallTime >= 0.2) {
        printf("CA_HOLD elapsed=%.6f presentation=%.6f model=%.3f\n", elapsed,
            self.square.layer.presentationLayer.opacity, self.square.layer.opacity);
        self.status.text = @"Paused";
        self.pauseWallTime = now + 1000;
    } else if (self.phase == 2 && elapsed >= 2.1) {
        [link invalidate];
        self.status.text = @"Finished";
        printf("CA_RUN_END presentation=%.3f model=%.3f\n", self.square.layer.presentationLayer.opacity,
            self.square.layer.opacity);
    }
}
- (void)resume:(id)sender {
    self.square.layer.speed = 1;
    self.square.layer.timeOffset = 0;
    self.square.layer.beginTime = CACurrentMediaTime() - self.pausedTime;
    self.phase = 2;
    self.status.text = @"Resumed";
    printf("CA_RESUME\n");
}
- (void)remove:(id)sender {
    [self.square.layer removeAnimationForKey:@"fade"];
    self.status.text = @"Removing";
    printf("CA_REMOVE presentation=%.3f model=%.3f\n", self.square.layer.presentationLayer.opacity,
        self.square.layer.opacity);
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(removalCommitted:) userInfo:nil repeats:NO];
}
- (void)removalCommitted:(NSTimer *)timer {
    self.status.text = @"Removed";
    printf("CA_REMOVED presentation=%.3f model=%.3f\n", self.square.layer.presentationLayer.opacity,
        self.square.layer.opacity);
}
- (void)unwatched:(id)sender {
    self.square.layer.beginTime = 0;
    self.startTime = CACurrentMediaTime() + 0.2;
    [self install:1.5];
    self.status.text = @"Unwatched";
    printf("CA_UNWATCHED_START\n");
    [NSTimer scheduledTimerWithTimeInterval:1.9 target:self selector:@selector(unwatchedEnd:) userInfo:nil repeats:NO];
}
- (void)unwatchedEnd:(NSTimer *)timer {
    self.status.text = @"Unwatched finished";
    printf("CA_UNWATCHED_END presentation=%.3f model=%.3f\n", self.square.layer.presentationLayer.opacity,
        self.square.layer.opacity);
}
@end
