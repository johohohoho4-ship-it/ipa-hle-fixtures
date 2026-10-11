#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 60, 358, 28)];
    title.accessibilityIdentifier = @"symbols.title";
    title.text = @"Ersatzsymbole, nicht SF Symbols";
    title.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    title.textColor = UIColor.labelColor;
    title.adjustsFontSizeToFitWidth = YES;
    [self.view addSubview:title];

    UILabel *note = [[UILabel alloc] initWithFrame:CGRectMake(16, 90, 358, 20)];
    note.text = @"Ersatz, nicht SF Symbols. Eigene Glyphen.";
    note.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    note.textColor = UIColor.secondaryLabelColor;
    [self.view addSubview:note];

    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:22
                                                                                                 weight:UIFontWeightMedium
                                                                                                  scale:UIImageSymbolScaleMedium];
    NSArray<NSString *> *names = @[
        @"checkmark", @"xmark", @"plus", @"minus",
        @"chevron.left", @"chevron.right", @"chevron.up", @"chevron.down",
        @"arrow.left", @"arrow.right", @"star", @"star.fill",
        @"heart", @"heart.fill", @"magnifyingglass", @"gear",
        @"person", @"house", @"bell", @"trash",
        @"info.circle", @"ellipsis", @"play.fill", @"pause.fill",
        @"doc", @"folder", @"lock", @"eye",
        @"pencil", @"questionmark", @"wifi", @"photo",
        @"circle", @"circle.fill"
    ];
    for (NSUInteger index = 0; index < names.count; index++) {
        NSString *name = names[index];
        NSInteger column = index % 4;
        NSInteger row = index / 4;
        CGFloat x = 12 + column * 94;
        CGFloat y = 124 + row * 70;
        UIImageView *icon = [[UIImageView alloc] initWithFrame:CGRectMake(x + 32, y, 28, 28)];
        icon.accessibilityIdentifier = name;
        icon.image = [UIImage systemImageNamed:name withConfiguration:configuration];
        icon.tintColor = UIColor.labelColor;
        icon.contentMode = UIViewContentModeScaleAspectFit;
        [self.view addSubview:icon];

        UILabel *caption = [[UILabel alloc] initWithFrame:CGRectMake(x, y + 30, 90, 28)];
        caption.text = name;
        caption.font = [UIFont systemFontOfSize:9 weight:UIFontWeightRegular];
        caption.textColor = UIColor.secondaryLabelColor;
        caption.textAlignment = NSTextAlignmentCenter;
        caption.numberOfLines = 2;
        [self.view addSubview:caption];
    }
}

@end
