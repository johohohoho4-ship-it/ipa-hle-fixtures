#import "ViewController.h"
@import QuartzCore;
#include <stdio.h>

// G8 reference: CAGradientLayer and CAShapeLayer. Every line starts with SBLAYER; the HLE replays the same app and
// must print the same lines (defaults, values after they are set). The four layers are also on the screenshot
// the XCUITest attaches, which the strict HLE run compares pixel by pixel.

@interface ViewController ()
@property(nonatomic, strong) UILabel *status;
@end

static NSString *Components(CGColorRef color) {
    if (!color) return @"nil";
    CGFloat r = 0, g = 0, b = 0, a = 0;
    UIColor *c = [UIColor colorWithCGColor:color];
    [c getRed:&r green:&g blue:&b alpha:&a];
    return [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", r, g, b, a];
}

static NSString *Frame(CGRect r) { return [NSString stringWithFormat:@"%g,%g,%g,%g", r.origin.x, r.origin.y, r.size.width, r.size.height]; }

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;

    CAGradientLayer *plain = [CAGradientLayer layer];
    printf("SBLAYER gradient-defaults colors=%lu locations=%lu start=%g,%g end=%g,%g type=%s\n", (unsigned long)plain.colors.count,
           (unsigned long)plain.locations.count, plain.startPoint.x, plain.startPoint.y, plain.endPoint.x, plain.endPoint.y,
           plain.type.UTF8String);
    CAShapeLayer *bare = [CAShapeLayer layer];
    printf("SBLAYER shape-defaults path=%d fill=%s stroke=%s width=%g miter=%g cap=%s join=%s rule=%s phase=%g dashes=%lu start=%g end=%g\n",
           bare.path != NULL, Components(bare.fillColor).UTF8String, Components(bare.strokeColor).UTF8String, bare.lineWidth,
           bare.miterLimit, bare.lineCap.UTF8String, bare.lineJoin.UTF8String, bare.fillRule.UTF8String, bare.lineDashPhase,
           (unsigned long)bare.lineDashPattern.count, bare.strokeStart, bare.strokeEnd);

    CAGradientLayer *two = [CAGradientLayer layer];
    two.frame = CGRectMake(20, 100, 150, 100);
    two.colors = @[(id)UIColor.redColor.CGColor, (id)UIColor.blueColor.CGColor];
    [self.view.layer addSublayer:two];

    CAGradientLayer *three = [CAGradientLayer layer];
    three.frame = CGRectMake(190, 100, 150, 100);
    three.colors = @[(id)UIColor.yellowColor.CGColor, (id)UIColor.greenColor.CGColor, (id)UIColor.blackColor.CGColor];
    three.locations = @[@0, @0.3, @1];
    three.startPoint = CGPointMake(0, 0);
    three.endPoint = CGPointMake(1, 1);
    [self.view.layer addSublayer:three];

    CAShapeLayer *oval = [CAShapeLayer layer];
    oval.frame = CGRectMake(20, 230, 150, 150);
    oval.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(10, 10, 130, 130)].CGPath;
    oval.fillColor = UIColor.greenColor.CGColor;
    oval.strokeColor = UIColor.blackColor.CGColor;
    oval.lineWidth = 6;
    oval.lineCap = kCALineCapRound;
    oval.lineDashPattern = @[@12, @6];
    [self.view.layer addSublayer:oval];

    CAShapeLayer *star = [CAShapeLayer layer];
    star.frame = CGRectMake(190, 230, 150, 150);
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint center = CGPointMake(75, 75);
    for (int i = 0; i < 5; i++) {                                   // a pentagram: one self-intersecting outline
        double angle = -M_PI / 2 + i * 4 * M_PI / 5;
        CGPoint p = CGPointMake(center.x + 65 * cos(angle), center.y + 65 * sin(angle));
        if (i == 0) [path moveToPoint:p]; else [path addLineToPoint:p];
    }
    [path closePath];
    star.path = path.CGPath;
    star.fillColor = UIColor.blueColor.CGColor;
    star.strokeColor = UIColor.redColor.CGColor;
    star.lineWidth = 3;
    star.lineJoin = kCALineJoinRound;
    star.fillRule = kCAFillRuleEvenOdd;
    [self.view.layer addSublayer:star];

    printf("SBLAYER two colors=%lu first=%s last=%s start=%g,%g end=%g,%g\n", (unsigned long)two.colors.count,
           Components((__bridge CGColorRef)two.colors.firstObject).UTF8String, Components((__bridge CGColorRef)two.colors.lastObject).UTF8String,
           two.startPoint.x, two.startPoint.y, two.endPoint.x, two.endPoint.y);
    printf("SBLAYER three locations=%s start=%g,%g end=%g,%g\n", [[three.locations componentsJoinedByString:@","] UTF8String],
           three.startPoint.x, three.startPoint.y, three.endPoint.x, three.endPoint.y);
    printf("SBLAYER oval fill=%s stroke=%s width=%g cap=%s dashes=%s frame=%s\n", Components(oval.fillColor).UTF8String,
           Components(oval.strokeColor).UTF8String, oval.lineWidth, oval.lineCap.UTF8String,
           [[oval.lineDashPattern componentsJoinedByString:@","] UTF8String], Frame(oval.frame).UTF8String);
    printf("SBLAYER star fill=%s stroke=%s width=%g join=%s rule=%s bounds=%s\n", Components(star.fillColor).UTF8String,
           Components(star.strokeColor).UTF8String, star.lineWidth, star.lineJoin.UTF8String, star.fillRule.UTF8String,
           Frame(CGPathGetBoundingBox(star.path)).UTF8String);
    printf("SBLAYER sublayers=%lu\n", (unsigned long)self.view.layer.sublayers.count);

    self.status = [[UILabel alloc] initWithFrame:CGRectMake(30, 410, 330, 40)];
    self.status.text = @"Ready";
    self.status.textColor = UIColor.blackColor;
    self.status.accessibilityIdentifier = @"sl.status";
    [self.view addSubview:self.status];
}

@end
