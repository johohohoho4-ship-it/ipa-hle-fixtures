#import "ViewControllers.h"
#include <stdio.h>

static void Describe(const char *what, UIImageView *view) {
    UIImage *image = view.image;
    printf("SBIMG %s image=%d size=%gx%g scale=%g mode=%d clips=%d frame=%g,%g,%g,%g\n", what, image != nil,
           image.size.width, image.size.height, image.scale, (int)view.contentMode, view.clipsToBounds,
           view.frame.origin.x, view.frame.origin.y, view.frame.size.width, view.frame.size.height);
}

@implementation SBImagesViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    Describe("fill", self.fillView);
    Describe("fit", self.fitView);
    Describe("center", self.centerView);
    Describe("empty", self.emptyView);
    printf("SBIMG fit same as named=%d\n", self.fitView.image == [UIImage imageNamed:@"photo.jpg"]);
}
@end
