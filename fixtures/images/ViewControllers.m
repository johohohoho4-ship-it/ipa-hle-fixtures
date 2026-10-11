#import "ViewControllers.h"
#include <stdio.h>

static void Describe(const char *what, UIImage *image) {
    if (!image) {
        printf("IMG %s nil=1\n", what);
        return;
    }
    printf("IMG %s size=%gx%g scale=%g pixels=%zux%zu orient=%d mode=%d\n", what, image.size.width, image.size.height,
           image.scale, CGImageGetWidth(image.CGImage), CGImageGetHeight(image.CGImage), (int)image.imageOrientation,
           (int)image.renderingMode);
}

static UIImageView *Cell(UIView *parent, UIImage *image, UIViewContentMode mode, CGRect frame, NSString *identifier) {
    UIImageView *view = [[UIImageView alloc] initWithFrame:frame];
    view.contentMode = mode;
    view.clipsToBounds = YES;
    view.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1.0];
    view.image = image;
    view.accessibilityIdentifier = identifier;
    [parent addSubview:view];
    return view;
}

@implementation ImagesViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = @"images.root";
    NSBundle *bundle = NSBundle.mainBundle;

    UIImage *badge = [UIImage imageNamed:@"badge"];
    UIImage *halves = [UIImage imageNamed:@"halves"];
    UIImage *photo = [UIImage imageNamed:@"photo.jpg"];
    UIImage *frames = [UIImage imageNamed:@"frames.gif"];
    UIImage *pic = [UIImage imageNamed:@"pic.heic"];
    UIImage *glyph = [UIImage imageNamed:@"glyph"];
    Describe("named badge", badge);
    Describe("named badge@2x", [UIImage imageNamed:@"badge@2x"]);
    Describe("named badge@3x", [UIImage imageNamed:@"badge@3x"]);
    Describe("named badge@2x.png", [UIImage imageNamed:@"badge@2x.png"]);
    Describe("named badge@3x.png", [UIImage imageNamed:@"badge@3x.png"]);
    Describe("named halves", halves);
    Describe("named photo", [UIImage imageNamed:@"photo"]);
    Describe("named photo.jpg", photo);
    Describe("named frames.gif", frames);
    Describe("named pic.heic", pic);
    Describe("named glyph", glyph);
    Describe("named nothere", [UIImage imageNamed:@"nothere"]);
    printf("IMG same object=%d\n", [UIImage imageNamed:@"badge"] == badge);

    Describe("file badge@2x", [UIImage imageWithContentsOfFile:[bundle pathForResource:@"badge@2x" ofType:@"png"]]);
    Describe("file photo", [UIImage imageWithContentsOfFile:[bundle pathForResource:@"photo" ofType:@"jpg"]]);
    Describe("file missing", [UIImage imageWithContentsOfFile:@"/nonexistent/none.png"]);
    NSData *data = [NSData dataWithContentsOfFile:[bundle pathForResource:@"halves" ofType:@"png"]];
    Describe("data halves", [UIImage imageWithData:data]);
    Describe("data halves scale2", [UIImage imageWithData:data scale:2.0]);
    Describe("data init", [[UIImage alloc] initWithData:data]);
    Describe("data garbage", [UIImage imageWithData:[NSData dataWithBytes:"junk" length:4]]);
    UIImage *template = [glyph imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    Describe("glyph template", template);
    printf("IMG original mode=%d\n", (int)glyph.renderingMode);

    UIImageView *probe = [[UIImageView alloc] initWithImage:badge];
    printf("IMG initWithImage frame=%gx%g mode=%d same=%d\n", probe.frame.size.width, probe.frame.size.height,
           (int)probe.contentMode, probe.image == badge);

    CGRect cell = CGRectMake(0, 0, 110, 64);
    CGFloat x0 = 20, x1 = 150, y = 120, dy = 76;
    Cell(self.view, photo, UIViewContentModeScaleToFill, CGRectOffset(cell, x0, y), @"images.fill");
    Cell(self.view, photo, UIViewContentModeScaleAspectFit, CGRectOffset(cell, x1, y), @"images.fit");
    Cell(self.view, photo, UIViewContentModeScaleAspectFill, CGRectOffset(cell, x0, y + dy), @"images.aspectfill");
    Cell(self.view, halves, UIViewContentModeCenter, CGRectOffset(cell, x1, y + dy), @"images.center");
    Cell(self.view, halves, UIViewContentModeTopLeft, CGRectOffset(cell, x0, y + 2 * dy), @"images.topleft");
    Cell(self.view, halves, UIViewContentModeBottomRight, CGRectOffset(cell, x1, y + 2 * dy), @"images.bottomright");
    UIImageView *tinted = Cell(self.view, template, UIViewContentModeCenter, CGRectOffset(cell, x0, y + 3 * dy), @"images.template");
    tinted.tintColor = [UIColor colorWithRed:0.9 green:0.2 blue:0.1 alpha:1.0];
    Cell(self.view, glyph, UIViewContentModeCenter, CGRectOffset(cell, x1, y + 3 * dy), @"images.original");
    Cell(self.view, frames, UIViewContentModeScaleToFill, CGRectOffset(cell, x0, y + 4 * dy), @"images.gif");
    Cell(self.view, pic, UIViewContentModeScaleAspectFit, CGRectOffset(cell, x1, y + 4 * dy), @"images.heic");
    Cell(self.view, badge, UIViewContentModeCenter, CGRectOffset(cell, x0, y + 5 * dy), @"images.badge");
}
@end
