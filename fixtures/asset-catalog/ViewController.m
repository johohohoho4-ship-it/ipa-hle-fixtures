#import "ViewController.h"
#import <CoreGraphics/CoreGraphics.h>
#include <stdio.h>
#include <stdlib.h>

static void ProbeImage(const char *tag, UIImage *image) {
    if (!image) {
        printf("AC_IMG name=%s nil=1\n", tag);
        return;
    }
    CGImageRef cg = image.CGImage;
    size_t w = CGImageGetWidth(cg);
    size_t h = CGImageGetHeight(cg);
    int r = -1, g = -1, b = -1, a = -1;
    if (w > 0 && h > 0) {
        size_t stride = w * 4;
        unsigned char *buf = (unsigned char *)calloc(h, stride);
        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        CGContextRef ctx = CGBitmapContextCreate(buf, w, h, 8, stride, cs, kCGImageAlphaPremultipliedLast);
        if (ctx) {
            CGContextDrawImage(ctx, CGRectMake(0, 0, (CGFloat)w, (CGFloat)h), cg);
            const unsigned char *px = (const unsigned char *)CGBitmapContextGetData(ctx);
            if (px) {
                size_t off = (h / 2) * stride + (w / 2) * 4;
                r = px[off];
                g = px[off + 1];
                b = px[off + 2];
                a = px[off + 3];
            }
            CGContextRelease(ctx);
        }
        CGColorSpaceRelease(cs);
        free(buf);
    }
    printf("AC_IMG name=%s size=%gx%g scale=%g pixels=%zux%zu center=%d,%d,%d,%d\n",
           tag, image.size.width, image.size.height, image.scale, w, h, r, g, b, a);
}

static UIImageView *AddTile(UIView *parent, UIImage *image, CGRect frame, NSString *identifier) {
    UIImageView *view = [[UIImageView alloc] initWithFrame:frame];
    view.contentMode = UIViewContentModeScaleAspectFit;
    view.clipsToBounds = YES;
    view.backgroundColor = [UIColor colorWithWhite:0.90 alpha:1.0];
    view.image = image;
    view.accessibilityIdentifier = identifier;
    [parent addSubview:view];
    return view;
}

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.accessibilityIdentifier = @"ac.root";

    printf("AC_START\n");
    UITraitCollection *lightTraits =
        [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
    UITraitCollection *darkTraits =
        [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];

    UIImage *scaleAll = [UIImage imageNamed:@"ScaleAll"];
    UIImage *scaleTwo = [UIImage imageNamed:@"ScaleTwo"];
    UIImage *scaleOne = [UIImage imageNamed:@"ScaleOne"];
    UIImage *themedLight = [UIImage imageNamed:@"Themed" inBundle:nil compatibleWithTraitCollection:lightTraits];
    UIImage *themedDark = [UIImage imageNamed:@"Themed" inBundle:nil compatibleWithTraitCollection:darkTraits];
    UIImage *packedA = [UIImage imageNamed:@"PackedA"];
    UIImage *packedB = [UIImage imageNamed:@"PackedB"];
    UIImage *banner = [UIImage imageNamed:@"Banner"];
    UIImage *groupA = [UIImage imageNamed:@"GroupA/Mark"];
    UIImage *groupB = [UIImage imageNamed:@"GroupB/Mark"];
    UIImage *unqualified = [UIImage imageNamed:@"Mark"];
    UIImage *missing = [UIImage imageNamed:@"Missing"];

    ProbeImage("ScaleAll", scaleAll);
    ProbeImage("ScaleTwo", scaleTwo);
    ProbeImage("ScaleOne", scaleOne);
    ProbeImage("Themed.light", themedLight);
    ProbeImage("Themed.dark", themedDark);
    ProbeImage("PackedA", packedA);
    ProbeImage("PackedB", packedB);
    ProbeImage("Banner", banner);
    ProbeImage("GroupA/Mark", groupA);
    ProbeImage("GroupB/Mark", groupB);
    ProbeImage("Mark", unqualified);
    ProbeImage("Missing", missing);
    printf("AC_DONE\n");

    UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(20, 64, 340, 32)];
    status.text = @"ready";
    status.textColor = [UIColor blackColor];
    status.accessibilityIdentifier = @"ac.status";
    [self.view addSubview:status];

    AddTile(self.view, scaleAll, CGRectMake(20, 112, 80, 80), @"ac.scaleAll");
    AddTile(self.view, scaleTwo, CGRectMake(116, 112, 80, 80), @"ac.scaleTwo");
    AddTile(self.view, scaleOne, CGRectMake(212, 112, 80, 80), @"ac.scaleOne");

    AddTile(self.view, themedLight, CGRectMake(20, 208, 128, 80), @"ac.themedLight");
    AddTile(self.view, themedDark, CGRectMake(164, 208, 128, 80), @"ac.themedDark");

    AddTile(self.view, packedA, CGRectMake(20, 304, 80, 80), @"ac.packedA");
    AddTile(self.view, packedB, CGRectMake(116, 304, 80, 80), @"ac.packedB");
    AddTile(self.view, groupA, CGRectMake(212, 304, 80, 80), @"ac.groupA");
    AddTile(self.view, groupB, CGRectMake(308, 304, 60, 80), @"ac.groupB");

    AddTile(self.view, banner, CGRectMake(20, 404, 240, 80), @"ac.banner");
}

@end
