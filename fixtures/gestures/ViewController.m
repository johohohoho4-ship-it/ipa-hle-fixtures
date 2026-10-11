#import "ViewController.h"
#include <stdio.h>

@interface ViewController ()
@property(nonatomic, strong) UIView *surface;
@property(nonatomic, strong) UIView *child;
@property(nonatomic, strong) UITapGestureRecognizer *tap;
@property(nonatomic, strong) UILabel *status;
@property(nonatomic) NSInteger count;
@end
@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.surface = [[UIView alloc] initWithFrame:CGRectMake(40, 110, 200, 160)];
    self.surface.backgroundColor = UIColor.blueColor;
    self.surface.accessibilityIdentifier = @"tg.surface";
    [self.view addSubview:self.surface];
    self.child = [[UIView alloc] initWithFrame:CGRectMake(30, 40, 100, 60)];
    self.child.backgroundColor = UIColor.greenColor;
    self.child.accessibilityIdentifier = @"tg.child";
    [self.surface addSubview:self.child];
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [self.surface addGestureRecognizer:self.tap];
    printf("TG_CONFIG state=%ld enabled=%d taps=%lu required=%lu cancels=%d began=%d ended=%d view=%d list=%lu\n",
        (long)self.tap.state, self.tap.enabled, (unsigned long)self.tap.numberOfTapsRequired,
        (unsigned long)self.tap.numberOfTouchesRequired, self.tap.cancelsTouchesInView,
        self.tap.delaysTouchesBegan, self.tap.delaysTouchesEnded, self.tap.view == self.surface,
        (unsigned long)self.surface.gestureRecognizers.count);
    self.status = [[UILabel alloc] initWithFrame:CGRectMake(30, 300, 340, 50)];
    self.status.text = @"Ready";
    self.status.accessibilityIdentifier = @"tg.status";
    [self.view addSubview:self.status];
}
- (void)tapped:(UITapGestureRecognizer *)sender {
    self.count++;
    CGPoint local = [sender locationInView:self.surface];
    CGPoint child = [sender locationInView:self.child];
    CGPoint window = [sender locationInView:nil];
    printf("TG_ACTION count=%ld state=%ld touches=%lu local=%.1f,%.1f child=%.1f,%.1f window=%.1f,%.1f view=%d\n",
        (long)self.count, (long)sender.state, (unsigned long)sender.numberOfTouches,
        local.x, local.y, child.x, child.y, window.x, window.y, sender.view == self.surface);
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(idle:) userInfo:nil repeats:NO];
}
- (void)idle:(NSTimer *)timer {
    CGPoint local = [self.tap locationInView:self.surface];
    printf("TG_IDLE count=%ld state=%ld touches=%lu local=%.1f,%.1f\n", (long)self.count,
        (long)self.tap.state, (unsigned long)self.tap.numberOfTouches, local.x, local.y);
    self.status.text = [NSString stringWithFormat:@"Idle %ld", (long)self.count];
}
@end
