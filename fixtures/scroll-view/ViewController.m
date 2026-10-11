#import "ViewController.h"
#include <stdio.h>
#import <QuartzCore/QuartzCore.h>

@interface ViewController () <UIScrollViewDelegate>
@property(nonatomic, strong) UIScrollView *scroll;
@property(nonatomic, strong) UILabel *status;
@property(nonatomic) NSInteger step;
@end
@implementation ViewController
- (void)report:(NSString *)phase {
    CGPoint p = self.scroll.contentOffset; CGSize s = self.scroll.contentSize;
    UIEdgeInsets i = self.scroll.contentInset, a = self.scroll.adjustedContentInset; CGRect b = self.scroll.bounds;
    printf("SCR_STATE phase=%s offset=%.3f,%.3f size=%.3f,%.3f inset=%.3f,%.3f,%.3f,%.3f adjusted=%.3f,%.3f,%.3f,%.3f bounds=%.3f,%.3f,%.3f,%.3f tracking=%d dragging=%d decel=%d\n",
        phase.UTF8String, p.x,p.y,s.width,s.height,i.top,i.left,i.bottom,i.right,a.top,a.left,a.bottom,a.right,
        b.origin.x,b.origin.y,b.size.width,b.size.height,self.scroll.tracking,self.scroll.dragging,self.scroll.decelerating);
}
- (void)viewDidLoad {
    [super viewDidLoad]; self.view.backgroundColor = UIColor.whiteColor;
    self.scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(40,110,220,240)];
    self.scroll.accessibilityIdentifier = @"scroll.viewport"; self.scroll.backgroundColor = UIColor.grayColor;
    printf("SCR_CONFIG clips=%d bounces=%d vertical=%d horizontal=%d enabled=%d paging=%d directional=%d delay=%d cancel=%d top=%d adjust=%ld rate=%.3f\n",
        self.scroll.clipsToBounds,self.scroll.bounces,self.scroll.alwaysBounceVertical,self.scroll.alwaysBounceHorizontal,
        self.scroll.scrollEnabled,self.scroll.pagingEnabled,self.scroll.directionalLockEnabled,
        self.scroll.delaysContentTouches,self.scroll.canCancelContentTouches,self.scroll.scrollsToTop,
        (long)self.scroll.contentInsetAdjustmentBehavior,(double)self.scroll.decelerationRate);
    self.scroll.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    self.scroll.bounces = NO; self.scroll.delegate = self; [self.view addSubview:self.scroll];
    [self report:@"empty"];
    self.scroll.contentSize = CGSizeMake(500,900);
    NSArray<UIColor *> *colors = @[UIColor.blueColor,UIColor.greenColor,UIColor.redColor];
    for (NSInteger n=0;n<3;n++) {
        UIView *row = [[UIView alloc] initWithFrame:CGRectMake(0,n*150,500,150)];
        row.backgroundColor = colors[n]; [self.scroll addSubview:row];
    }
    [self report:@"content"];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem]; button.frame = CGRectMake(40,390,220,45);
    [button setTitle:@"Advance" forState:UIControlStateNormal]; button.accessibilityIdentifier = @"scroll.advance";
    [button addTarget:self action:@selector(advance:) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:button];
    self.status = [[UILabel alloc] initWithFrame:CGRectMake(30,480,330,45)]; self.status.text = @"Ready";
    self.status.accessibilityIdentifier = @"scroll.status"; [self.view addSubview:self.status];
}
- (void)advance:(UIButton *)sender {
    self.step++; printf("SCR_BEFORE step=%ld\n",(long)self.step);
    if (self.step == 1) self.scroll.contentOffset = CGPointMake(35,80);
    if (self.step == 2) self.scroll.contentInset = UIEdgeInsetsMake(10,20,30,40);
    if (self.step == 3) [self.scroll scrollRectToVisible:CGRectMake(400,800,20,30) animated:NO];
    if (self.step == 4) {
        self.scroll.contentSize = CGSizeMake(150,100); [self report:@"smaller"];
        [self.scroll setContentOffset:CGPointMake(-15,-5) animated:NO];
    }
    if (self.step == 5) {
        self.scroll.contentSize = CGSizeMake(500,900); self.scroll.contentInset = UIEdgeInsetsZero;
        self.scroll.contentOffset = CGPointMake(0,60);
        [self.scroll.panGestureRecognizer addTarget:self action:@selector(panned:)];
    }
    [self report:@"after"]; printf("SCR_AFTER step=%ld\n",(long)self.step);
    self.status.text = [NSString stringWithFormat:@"Done %ld",(long)self.step];
}
- (void)panned:(UIPanGestureRecognizer *)pan {
    CGPoint p = [pan locationInView:nil], t = [pan translationInView:nil], o = self.scroll.contentOffset;
    printf("SCR_PAN state=%ld touches=%lu point=%.3f,%.3f translation=%.3f,%.3f offset=%.3f,%.3f time=%.6f\n",
        (long)pan.state,(unsigned long)pan.numberOfTouches,p.x,p.y,t.x,t.y,o.x,o.y,CACurrentMediaTime());
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    CGPoint p = scrollView.contentOffset;
    printf("SCR_DRAG begin offset=%.3f,%.3f tracking=%d dragging=%d\n",p.x,p.y,scrollView.tracking,scrollView.dragging);
}
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)target {
    printf("SCR_DRAG willEnd velocity=%.3f,%.3f target=%.3f,%.3f tracking=%d dragging=%d\n",
        velocity.x,velocity.y,target->x,target->y,scrollView.tracking,scrollView.dragging);
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    printf("SCR_DRAG end decelerate=%d tracking=%d dragging=%d\n",decelerate,scrollView.tracking,scrollView.dragging);
    [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(idle:) userInfo:nil repeats:NO];
}
- (void)idle:(NSTimer *)timer {
    [self report:@"idle"]; self.status.text = @"Drag Idle";
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint p = scrollView.contentOffset; CGRect b = scrollView.bounds;
    printf("SCR_CALLBACK did offset=%.3f,%.3f bounds=%.3f,%.3f tracking=%d dragging=%d decel=%d\n",
        p.x,p.y,b.origin.x,b.origin.y,scrollView.tracking,scrollView.dragging,scrollView.decelerating);
}
@end
