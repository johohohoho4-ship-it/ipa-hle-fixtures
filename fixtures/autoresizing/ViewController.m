#import "ViewController.h"
#include <stdio.h>

static void LogFrame(const char *name, NSInteger mask, NSInteger step, UIView *view) {
    CGRect r = view.frame;
    printf("AR_SAMPLE %s mask=%ld step=%ld %.6f %.6f %.6f %.6f\n", name, (long)mask, (long)step,
        r.origin.x, r.origin.y, r.size.width, r.size.height);
}

static void Probe(const char *name, NSUInteger mask, CGRect frame, CGSize oldSize, CGSize newSize, BOOL bounds) {
    UIView *parent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, oldSize.width, oldSize.height)];
    UIView *child = [[UIView alloc] initWithFrame:frame];
    child.autoresizingMask = mask;
    [parent addSubview:child];
    if (bounds) parent.bounds = CGRectMake(0, 0, newSize.width, newSize.height);
    else parent.frame = CGRectMake(0, 0, newSize.width, newSize.height);
    LogFrame(name, mask, 1, child);
    if (bounds) parent.bounds = CGRectMake(0, 0, oldSize.width, oldSize.height);
    else parent.frame = CGRectMake(0, 0, oldSize.width, oldSize.height);
    LogFrame(name, mask, 2, child);
}

static void Detail(const char *name, NSUInteger mask, UIView *child) {
    CGRect r = child.frame;
    CGSize b = child.bounds.size;
    CGPoint c = child.center;
    printf("AR_DETAIL %s mask=%lu frame %.9f %.9f bounds %.9f center %.9f\n", name, (unsigned long)mask,
        r.origin.x, r.size.width, b.width, c.x);
}

static void ConstraintProbe(UIView *root) {
    UIView *parent = [[UIView alloc] initWithFrame:CGRectZero];
    parent.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:parent];
    NSLayoutConstraint *width = [parent.widthAnchor constraintEqualToConstant:320];
    [NSLayoutConstraint activateConstraints:@[
        [parent.leadingAnchor constraintEqualToAnchor:root.leadingAnchor constant:0],
        [parent.topAnchor constraintEqualToAnchor:root.topAnchor constant:0],
        width, [parent.heightAnchor constraintEqualToConstant:200]]];
    [root layoutIfNeeded];
    UIView *child = [[UIView alloc] initWithFrame:CGRectMake(10, 20, 100, 50)];
    child.autoresizingMask = 3;
    [parent addSubview:child];
    width.constant = 480;
    [root layoutIfNeeded];
    Detail("solver-grown", 3, child);
    width.constant = 640;
    [root layoutIfNeeded];
    Detail("solver-again", 3, child);
    width.constant = 320;
    [root layoutIfNeeded];
    Detail("solver-return", 3, child);
    [parent removeFromSuperview];
}

static void RoundingProbe(NSUInteger mask, BOOL resetFrame, BOOL resetMask) {
    UIView *parent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 200)];
    UIView *child = [[UIView alloc] initWithFrame:CGRectMake(10, 20, 100, 50)];
    child.autoresizingMask = mask;
    [parent addSubview:child];
    parent.frame = CGRectMake(0, 0, 480, 200);
    Detail("grown", mask, child);
    if (resetFrame) child.frame = child.frame;
    if (resetMask) { child.autoresizingMask = 0; child.autoresizingMask = mask; }
    parent.frame = CGRectMake(0, 0, 640, 200);
    Detail(resetFrame ? "reset-frame-grow" : resetMask ? "reset-mask-grow" : "again-grow", mask, child);
    parent.frame = CGRectMake(0, 0, 320, 200);
    Detail(resetFrame ? "reset-frame-return" : resetMask ? "reset-mask-return" : "again-return", mask, child);
}

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    for (NSUInteger mask = 1; mask <= 7; mask++) {
        Probe("horizontal-frame", mask, CGRectMake(10, 20, 100, 50), CGSizeMake(320, 200), CGSizeMake(480, 200), NO);
        Probe("horizontal-bounds", mask, CGRectMake(10, 20, 100, 50), CGSizeMake(320, 200), CGSizeMake(160, 200), YES);
        Probe("vertical-frame", mask << 3, CGRectMake(10, 20, 100, 50), CGSizeMake(320, 200), CGSizeMake(320, 300), NO);
        Probe("vertical-bounds", mask << 3, CGRectMake(10, 20, 100, 50), CGSizeMake(320, 200), CGSizeMake(320, 100), YES);
    }
    Probe("zero-margins", 5, CGRectMake(0, 20, 320, 50), CGSizeMake(320, 200), CGSizeMake(480, 200), NO);
    Probe("zero-size", 7, CGRectZero, CGSizeZero, CGSizeMake(300, 150), NO);
    Probe("zero-width-right", 6, CGRectMake(10, 20, 0, 50), CGSizeMake(10, 200), CGSizeMake(30, 200), NO);
    Probe("negative-right", 7, CGRectMake(10, 20, 100, 50), CGSizeMake(80, 200), CGSizeMake(120, 200), NO);
    RoundingProbe(3, NO, NO);
    RoundingProbe(5, NO, NO);
    RoundingProbe(6, NO, NO);
    RoundingProbe(3, YES, NO);
    RoundingProbe(5, YES, NO);
    RoundingProbe(6, YES, NO);
    RoundingProbe(5, NO, YES);
    Probe("fractional-fixed", 5, CGRectMake(10.1, 20, 100.2, 50), CGSizeMake(320, 200), CGSizeMake(480, 200), NO);
    Probe("zero-width-left", 3, CGRectMake(0, 20, 0, 50), CGSizeMake(320, 200), CGSizeMake(480, 200), NO);
    ConstraintProbe(self.view);
    UILabel *done = [[UILabel alloc] initWithFrame:CGRectMake(30, 100, 300, 50)];
    done.text = @"Autoresizing samples complete";
    done.accessibilityIdentifier = @"ar.done";
    [self.view addSubview:done];
    printf("AR_DONE\n");
}
@end
