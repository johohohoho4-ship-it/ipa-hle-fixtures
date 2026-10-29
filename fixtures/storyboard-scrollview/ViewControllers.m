#import "ViewControllers.h"
#include <stdio.h>
#include <math.h>
#import <QuartzCore/QuartzCore.h>
#import <dispatch/dispatch.h>

// F5/F9 reference: a UIScrollView decoded from Main.storyboard. Measured are the decoded
// scroll state (content size/offset/insets, bounces, scrolling flags, delegate, clipping,
// frame/bounds), the order of awakeFromNib/viewDidLoad/viewDidAppear with timestamps, the
// hierarchy and the frames after layout, the scroll callbacks of a real XCUITest swipe,
// and the re-measured state after setContentOffset:animated:NO and setContentInset:.
// Nothing here asserts an expected value; every printed number is read from UIKit.

static int gSeq = 0;
static int gDidScroll = 0;
static int gStep = 0;
static BOOL gDragSettled = NO;

static const char *str(NSString *value) { return value ? value.UTF8String : "nil"; }

static NSString *rectStr(CGRect r) {
    return [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", r.origin.x, r.origin.y, r.size.width, r.size.height];
}

static NSString *pointStr(CGPoint p) {
    return [NSString stringWithFormat:@"%.3f,%.3f", p.x, p.y];
}

static NSString *sizeStr(CGSize s) {
    return [NSString stringWithFormat:@"%.3f,%.3f", s.width, s.height];
}

static NSString *insetStr(UIEdgeInsets i) {
    return [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", i.top, i.left, i.bottom, i.right];
}

static NSString *rgbaStr(UIColor *c) {
    if (!c) return @"nil";
    CGFloat r = 0, g = 0, b = 0, a = 0;
    if (![c getRed:&r green:&g blue:&b alpha:&a]) return @"unconvertible";
    return [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", r, g, b, a];
}

@implementation SCNScrollViewController

#pragma mark - measurement helpers

- (void)printState:(const char *)phase {
    UIScrollView *scroll = self.scrollView;
    if (!scroll) {
        printf("SCN_CODER phase=%s seq=%d scroll=nil\n", phase, ++gSeq);
        return;
    }
    printf("SCN_CODER phase=%s seq=%d class=%s size=%s offset=%s inset=%s adjusted=%s frame=%s bounds=%s bounces=%d alwaysBounceVertical=%d alwaysBounceHorizontal=%d scrollEnabled=%d showsVertical=%d showsHorizontal=%d hasDelegate=%d delegate=%s clipsToBounds=%d contentInsetAdjustmentBehavior=%ld\n",
           phase, ++gSeq, object_getClassName(scroll), sizeStr(scroll.contentSize).UTF8String,
           pointStr(scroll.contentOffset).UTF8String, insetStr(scroll.contentInset).UTF8String,
           insetStr(scroll.adjustedContentInset).UTF8String, rectStr(scroll.frame).UTF8String,
           rectStr(scroll.bounds).UTF8String, scroll.bounces, scroll.alwaysBounceVertical,
           scroll.alwaysBounceHorizontal, scroll.scrollEnabled, scroll.showsVerticalScrollIndicator,
           scroll.showsHorizontalScrollIndicator, scroll.delegate != nil,
           scroll.delegate ? object_getClassName(scroll.delegate) : "nil", scroll.clipsToBounds,
           (long)scroll.contentInsetAdjustmentBehavior);
}

- (void)printHierarchy:(const char *)phase {
    UIScrollView *scroll = self.scrollView;
    UIView *container = self.containerView;
    if (!scroll) {
        printf("SCN_HIER phase=%s seq=%d scroll=nil\n", phase, ++gSeq);
        return;
    }
    BOOL sameSuperview = scroll.superview == self.view;
    NSInteger containerIndex = -1;
    if (container) {
        NSUInteger found = [scroll.subviews indexOfObjectIdenticalTo:container];
        if (found != NSNotFound) containerIndex = (NSInteger)found;
    }
    BOOL containerInScroll = container != nil && container.superview == scroll;
    printf("SCN_HIER phase=%s seq=%d scrollSuperviewIsView=%d scrollSuperview=%s view=%s containerOutlet=%d containerIndex=%ld containerSuperviewIsScroll=%d scrollSubviews=%lu containerSubviews=%lu containerFrame=%s containerBounds=%s contentSize=%s contentOffset=%s\n",
           phase, ++gSeq, sameSuperview, scroll.superview ? object_getClassName(scroll.superview) : "nil",
           object_getClassName(self.view), container != nil, (long)containerIndex,
           containerInScroll, (unsigned long)scroll.subviews.count,
           (unsigned long)(container ? container.subviews.count : 0),
           container ? rectStr(container.frame).UTF8String : "nil",
           container ? rectStr(container.bounds).UTF8String : "nil",
           sizeStr(scroll.contentSize).UTF8String, pointStr(scroll.contentOffset).UTF8String);
    NSUInteger index = 0;
    for (UIView *sub in scroll.subviews) {
        printf("SCN_SCROLLSUB phase=%s index=%lu class=%s frame=%s hidden=%d\n",
               phase, (unsigned long)index++, object_getClassName(sub), rectStr(sub.frame).UTF8String, sub.hidden);
    }
    index = 0;
    for (UIView *sub in container.subviews) {
        printf("SCN_SUB phase=%s index=%lu class=%s frame=%s bounds=%s bg=%s hidden=%d\n",
               phase, (unsigned long)index++, object_getClassName(sub), rectStr(sub.frame).UTF8String,
               rectStr(sub.bounds).UTF8String, rgbaStr(sub.backgroundColor).UTF8String, sub.hidden);
    }
}

- (void)reportSettledOffset:(const char *)reason {
    gDragSettled = YES;
    NSInteger rounded = (NSInteger)llround(self.scrollView.contentOffset.y);
    self.statusLabel.text = [NSString stringWithFormat:@"OFFSET %ld", (long)rounded];
    printf("SCN_SETTLE reason=%s offset=%s rounded=%ld didCount=%d dragging=%d decelerating=%d status=%s\n",
           reason, pointStr(self.scrollView.contentOffset).UTF8String, (long)rounded, gDidScroll,
           self.scrollView.dragging, self.scrollView.decelerating, str(self.statusLabel.text));
}

#pragma mark - lifecycle

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        printf("SCN_VC initcoder seq=%d t=%.6f class=%s\n", ++gSeq, CACurrentMediaTime(),
               object_getClassName(self));
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // The scene's view lives in its own nib. At this point the scroll outlet is not
    // connected yet; this is printed as measured instead of being guessed.
    printf("SCN_SEQ awake seq=%d t=%.6f scrollOutlet=%s\n", ++gSeq, CACurrentMediaTime(),
           self.scrollView ? object_getClassName(self.scrollView) : "nil");
    [self printState:"awake"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    printf("SCN_SEQ didload seq=%d t=%.6f\n", ++gSeq, CACurrentMediaTime());
    // First point where the scene's view nib has been loaded and its outlets are wired.
    [self printState:"didload"];
    [self printHierarchy:"didload"];

    UIView *container = self.containerView;
    if (container) {
        CGSize containerSize = container.bounds.size;
        self.scrollView.contentSize = containerSize;
        printf("SCN_CONTENT phase=didload source=containerOutlet size=%s\n", sizeStr(containerSize).UTF8String);
    } else if (self.scrollView.subviews.count > 0) {
        CGSize containerSize = self.scrollView.subviews[0].bounds.size;
        self.scrollView.contentSize = containerSize;
        printf("SCN_CONTENT phase=didload source=firstScrollSubview size=%s\n", sizeStr(containerSize).UTF8String);
    } else {
        printf("SCN_CONTENT phase=didload source=none size=0.000,0.000\n");
    }
    printf("SCN_CONFIG phase=didload statusText=%s stepTitle=%s scrollIdentifier=%s\n",
           str(self.statusLabel.text), str([self.stepButton titleForState:UIControlStateNormal]),
           str(self.scrollView.accessibilityIdentifier));
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    printf("SCN_SEQ appear seq=%d t=%.6f\n", ++gSeq, CACurrentMediaTime());
    [self printState:"appear"];
    [self printHierarchy:"appear"];
    printf("SCN_READY size=%s offset=%s bounds=%s didCount=%d\n",
           sizeStr(self.scrollView.contentSize).UTF8String,
           pointStr(self.scrollView.contentOffset).UTF8String,
           rectStr(self.scrollView.bounds).UTF8String, gDidScroll);
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    gDragSettled = NO;
    printf("SCN_DRAG begin offset=%s didCount=%d dragging=%d decelerating=%d\n",
           pointStr(scrollView.contentOffset).UTF8String, gDidScroll,
           scrollView.dragging, scrollView.decelerating);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    gDidScroll++;
    printf("SCN_CALLBACK did n=%d offset=%s bounds=%s dragging=%d decelerating=%d\n",
           gDidScroll, pointStr(scrollView.contentOffset).UTF8String,
           rectStr(scrollView.bounds).UTF8String, scrollView.dragging, scrollView.decelerating);
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    printf("SCN_DRAG end offset=%s didCount=%d decelerate=%d\n",
           pointStr(scrollView.contentOffset).UTF8String, gDidScroll, decelerate);
    if (!decelerate) {
        [self reportSettledOffset:"endDragging"];
    } else {
        // Fallback in case no deceleration callback follows; re-checks the live flags.
        __weak SCNScrollViewController *weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            SCNScrollViewController *strongSelf = weakSelf;
            if (strongSelf && !gDragSettled && !strongSelf.scrollView.dragging && !strongSelf.scrollView.decelerating) {
                [strongSelf reportSettledOffset:"timer"];
            }
        });
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    printf("SCN_DRAG decelerateEnd offset=%s didCount=%d\n",
           pointStr(scrollView.contentOffset).UTF8String, gDidScroll);
    [self reportSettledOffset:"endDecelerating"];
}

#pragma mark - actions

- (IBAction)stepPressed:(UIButton *)sender {
    gStep++;
    gDragSettled = YES;
    printf("SCN_STEP begin step=%d t=%.6f size=%s offset=%s inset=%s adjusted=%s\n",
           gStep, CACurrentMediaTime(), sizeStr(self.scrollView.contentSize).UTF8String,
           pointStr(self.scrollView.contentOffset).UTF8String,
           insetStr(self.scrollView.contentInset).UTF8String,
           insetStr(self.scrollView.adjustedContentInset).UTF8String);
    if (gStep == 1) {
        CGPoint target = CGPointMake(200, 300);
        printf("SCN_PROG call=setContentOffset target=%s animated=0\n", pointStr(target).UTF8String);
        [self.scrollView setContentOffset:target animated:NO];
        [self printState:"progoffset"];
    } else if (gStep == 2) {
        UIEdgeInsets inset = UIEdgeInsetsMake(10, 20, 30, 40);
        printf("SCN_PROG call=setContentInset value=%s\n", insetStr(inset).UTF8String);
        [self.scrollView setContentInset:inset];
        [self printState:"proginset"];
    } else {
        printf("SCN_PROG call=resetOffsetAndInset\n");
        [self.scrollView setContentOffset:CGPointMake(0, 0) animated:NO];
        [self.scrollView setContentInset:UIEdgeInsetsZero];
        [self printState:"progreset"];
    }
    self.statusLabel.text = [NSString stringWithFormat:@"PROG %d", gStep];
    printf("SCN_STEP end step=%d status=%s offset=%s inset=%s adjusted=%s didCount=%d\n",
           gStep, str(self.statusLabel.text), pointStr(self.scrollView.contentOffset).UTF8String,
           insetStr(self.scrollView.contentInset).UTF8String,
           insetStr(self.scrollView.adjustedContentInset).UTF8String, gDidScroll);
}

@end
