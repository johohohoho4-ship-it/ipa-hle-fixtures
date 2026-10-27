#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#include <stdio.h>

// K1/D5 prerequisites for corpus-2048 after the SpriteKit fix. Only observations:
// mutable collections created with -initWithCapacity:, arc4random_uniform bounds and
// a CALayer rendered into an offscreen image context, sampled as RGBA pixels.
@interface ViewController ()
@property(nonatomic, strong) UILabel *status;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    [self capacityChecks];
    [self randomChecks];
    [self renderChecks];
    UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(20, 520, 340, 40)];
    status.text = @"RC_DONE";
    status.accessibilityIdentifier = @"rc.status";
    [self.view addSubview:status];
    printf("RC_DONE\n");
}

- (void)capacityChecks {
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:4];
    [array addObject:@"a"];
    [array addObject:@"b"];
    printf("RC_ARRAY count=%lu first=%s\n", (unsigned long)array.count,
           [[array firstObject] UTF8String]);

    NSMutableSet *set = [[NSMutableSet alloc] initWithCapacity:4];
    [set addObject:@"a"];
    [set addObject:@"a"];
    [set addObject:@"b"];
    printf("RC_SET count=%lu contains_b=%d\n", (unsigned long)set.count,
           [set containsObject:@"b"] ? 1 : 0);

    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:4];
    dictionary[@"k"] = @1;
    printf("RC_DICT count=%lu value=%d\n", (unsigned long)dictionary.count,
           [dictionary[@"k"] intValue]);

    NSMutableArray *zero = [[NSMutableArray alloc] initWithCapacity:0];
    printf("RC_ZERO count=%lu\n", (unsigned long)zero.count);
}

- (void)randomChecks {
    const uint32_t bound = 10;
    int maximum = -1;
    int below = 1;
    for (int n = 0; n < 200; n++) {
        uint32_t value = arc4random_uniform(bound);
        if (value >= bound) below = 0;
        if ((int)value > maximum) maximum = (int)value;
    }
    printf("RC_RANDOM bound=10 below=%d max=%d zero=%u one=%u\n", below, maximum,
           arc4random_uniform(0), arc4random_uniform(1));
}

- (void)renderChecks {
    UIView *tree = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    tree.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:1];
    tree.layer.cornerRadius = 8;
    UIView *child = [[UIView alloc] initWithFrame:CGRectMake(10, 10, 20, 20)];
    child.backgroundColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:1];
    [tree addSubview:child];

    UIGraphicsBeginImageContextWithOptions(tree.bounds.size, YES, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [tree.layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    printf("RC_RENDER size=%.1f,%.1f pixels=%lu\n", image.size.width, image.size.height,
           (unsigned long)(image.CGImage ? CGImageGetWidth(image.CGImage) : 0));

    size_t width = 40, height = 40;
    unsigned char *pixels = calloc(width * height * 4, 1);
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmap = CGBitmapContextCreate(pixels, width, height, 8, width * 4, space,
                                                kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(bitmap, CGRectMake(0, 0, width, height), image.CGImage);
    size_t red = (18 * width + 6) * 4, blue = (26 * width + 20) * 4, outside = (1 * width + 1) * 4;
    printf("RC_PIXEL red=%d,%d,%d blue=%d,%d,%d outside=%d,%d,%d\n",
           pixels[red], pixels[red + 1], pixels[red + 2],
           pixels[blue], pixels[blue + 1], pixels[blue + 2],
           pixels[outside], pixels[outside + 1], pixels[outside + 2]);
    CGContextRelease(bitmap);
    CGColorSpaceRelease(space);
    free(pixels);
}

@end
