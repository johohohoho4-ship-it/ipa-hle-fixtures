#import "ViewController.h"
@import QuartzCore;
#include <stdio.h>

@interface ViewController ()
@property(nonatomic, strong) UIView *square;
@property(nonatomic, strong) UILabel *status;
@property(nonatomic) NSInteger stage;
@end
@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.square = [[UIView alloc] initWithFrame:CGRectMake(40, 110, 120, 120)];
    self.square.backgroundColor = UIColor.blueColor;
    self.square.accessibilityIdentifier = @"ca.square";
    [self.view addSubview:self.square];
    self.status = [[UILabel alloc] initWithFrame:CGRectMake(30, 250, 330, 40)];
    self.status.textColor = UIColor.blackColor;
    self.status.accessibilityIdentifier = @"ca.status";
    [self.view addSubview:self.status];
    NSArray *titles = @[@"Quarter", @"Half", @"After end", @"Remove"];
    for (NSInteger i=0; i<4; ++i) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectMake(30, 310 + i*60, 200, 44);
        [button setTitle:titles[i] forState:UIControlStateNormal];
        button.accessibilityIdentifier = [NSString stringWithFormat:@"ca.step%ld", (long)i+1];
        SEL actions[] = {@selector(quarter:), @selector(half:), @selector(afterEnd:), @selector(remove:)};
        [button addTarget:self action:actions[i] forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    }
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.square.layer.opacity = 0.8;
    self.square.layer.speed = 0;
    self.square.layer.timeOffset = 0;
    [CATransaction commit];
    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.fromValue = [NSNumber numberWithDouble:0.2];
    fade.toValue = [NSNumber numberWithDouble:1.0];
    fade.duration = 2;
    fade.timingFunction = [CAMediaTimingFunction functionWithName:@"linear"];
    fade.removedOnCompletion = NO;
    fade.fillMode = @"forwards";
    [self.square.layer addAnimation:fade forKey:@"fade"];
    fade.duration = 4;
    fade.fromValue = [NSNumber numberWithDouble:0.9];
    CABasicAnimation *copied = (CABasicAnimation *)[self.square.layer animationForKey:@"fade"];
    printf("CA_COPY duration=%.1f from=%.3f model=%.3f\n", copied.duration, [copied.fromValue doubleValue], self.square.layer.opacity);
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(sample:) userInfo:nil repeats:NO];
}
- (void)quarter:(id)sender { self.stage = 1; [self step]; }
- (void)half:(id)sender { self.stage = 2; [self step]; }
- (void)afterEnd:(id)sender { self.stage = 3; [self step]; }
- (void)remove:(id)sender { self.stage = 4; [self step]; }
- (void)step {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    if (self.stage == 4) [self.square.layer removeAnimationForKey:@"fade"];
    else self.square.layer.timeOffset = self.stage == 1 ? 0.5 : self.stage == 2 ? 1.0 : 2.5;
    [CATransaction commit];
    [CATransaction flush];
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(sample:) userInfo:nil repeats:NO];
}
- (void)sample:(NSTimer *)timer {
    float model = self.square.layer.opacity;
    float presented = self.square.layer.presentationLayer.opacity;
    printf("CA_SAMPLE stage=%ld model=%.3f presentation=%.3f\n", (long)self.stage, model, presented);
    self.status.text = [NSString stringWithFormat:@"Sample %ld %.3f", (long)self.stage, presented];
}
@end
