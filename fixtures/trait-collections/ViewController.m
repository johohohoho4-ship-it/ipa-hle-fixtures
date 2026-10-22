#import "ViewController.h"
#include <stdio.h>

@interface ViewController ()
@property (nonatomic, strong) UILabel *styleLabel;
@property (nonatomic, strong) UILabel *categoryLabel;
- (void)toggleAppearance;
- (void)updateTraitLabels;
- (void)logSystemColors;
- (void)logTraitAndFontProfiles;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.frame = UIScreen.mainScreen.bounds;
    self.view.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 110, 350, 48)];
    title.accessibilityIdentifier = @"trait.title";
    title.text = @"Trait Collection Fixture";
    title.font = [UIFont systemFontOfSize:25 weight:UIFontWeightSemibold];
    title.textColor = UIColor.labelColor;
    [self.view addSubview:title];

    self.styleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 175, 350, 44)];
    self.styleLabel.accessibilityIdentifier = @"trait.style";
    self.styleLabel.font = [UIFont preferredFontForTextStyle:@"UICTFontTextStyleBody"];
    self.styleLabel.textColor = UIColor.secondaryLabelColor;
    [self.view addSubview:self.styleLabel];

    self.categoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 235, 350, 95)];
    self.categoryLabel.accessibilityIdentifier = @"trait.dynamic-type";
    self.categoryLabel.numberOfLines = 2;
    self.categoryLabel.textColor = UIColor.labelColor;
    [self.view addSubview:self.categoryLabel];

    UIButton *toggle = [UIButton buttonWithType:UIButtonTypeSystem];
    toggle.frame = CGRectMake(20, 350, 280, 52);
    toggle.accessibilityIdentifier = @"trait.toggle-appearance";
    [toggle setTitle:@"Stil umschalten" forState:UIControlStateNormal];
    [toggle addTarget:self action:@selector(toggleAppearance) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:toggle];

    UILabel *classes = [[UILabel alloc] initWithFrame:CGRectMake(20, 430, 350, 48)];
    classes.accessibilityIdentifier = @"trait.size-classes";
    classes.textColor = UIColor.secondaryLabelColor;
    classes.font = [UIFont preferredFontForTextStyle:@"UICTFontTextStyleCaption1"];
    classes.text = [NSString stringWithFormat:@"Size classes: %ld / %ld",
                    (long)self.view.traitCollection.horizontalSizeClass,
                    (long)self.view.traitCollection.verticalSizeClass];
    [self.view addSubview:classes];

    [self logTraitAndFontProfiles];
    [self logSystemColors];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // The override set in viewDidLoad only reaches the view's trait collection once the view
    // is in the window; re-reading here makes the intended start-in-Dark observable.
    [self updateTraitLabels];
}

- (void)updateTraitLabels {
    UITraitCollection *traits = self.view.traitCollection;
    NSString *style = traits.userInterfaceStyle == UIUserInterfaceStyleDark ? @"Dark" : @"Light";
    self.styleLabel.text = [NSString stringWithFormat:@"Appearance: %@", style];
    self.categoryLabel.text = [NSString stringWithFormat:@"Dynamic Type: %.0f pt", self.categoryLabel.font.pointSize];
    printf("TR_STATE style=%ld h=%ld v=%ld category=%s\n",
           (long)traits.userInterfaceStyle, (long)traits.horizontalSizeClass,
           (long)traits.verticalSizeClass, traits.preferredContentSizeCategory.UTF8String);
}

- (void)toggleAppearance {
    self.view.overrideUserInterfaceStyle = self.view.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark
        ? UIUserInterfaceStyleLight : UIUserInterfaceStyleDark;
    // A new override reaches the view's trait collection on the next update pass, not
    // synchronously; read it once the run loop turns, as UIKit does.
    [self performSelector:@selector(updateTraitLabels) withObject:nil afterDelay:0];
}

- (void)logTraitAndFontProfiles {
    UITraitCollection *light = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
    UITraitCollection *regularWidth = [UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassRegular];
    UITraitCollection *largeCategory = [UITraitCollection traitCollectionWithPreferredContentSizeCategory:
        UIContentSizeCategoryAccessibilityExtraExtraExtraLarge];
    UITraitCollection *merged = [UITraitCollection traitCollectionWithTraitsFromCollections:@[light, regularWidth, largeCategory]];
    UIFont *base = [UIFont systemFontOfSize:17.0];
    UIFontMetrics *metrics = [UIFontMetrics metricsForTextStyle:@"UICTFontTextStyleBody"];
    UIFont *scaled = [metrics scaledFontForFont:base compatibleWithTraitCollection:merged];
    self.categoryLabel.font = scaled;
    UIFont *preferred = [UIFont preferredFontForTextStyle:@"UICTFontTextStyleBody" compatibleWithTraitCollection:merged];
    printf("TR_PROFILE style=%ld h=%ld category=%s contains=%d base=%.1f scaled=%.1f preferred=%.1f\n",
           (long)merged.userInterfaceStyle, (long)merged.horizontalSizeClass,
           merged.preferredContentSizeCategory.UTF8String,
           [merged containsTraitsInCollection:largeCategory], base.pointSize, scaled.pointSize, preferred.pointSize);
}

- (void)logSystemColors {
    NSArray<NSString *> *names = @[
        @"systemRed", @"systemOrange", @"systemYellow", @"systemGreen", @"systemMint", @"systemTeal",
        @"systemCyan", @"systemBlue", @"systemIndigo", @"systemPurple", @"systemPink", @"systemBrown",
        @"systemGray", @"systemGray2", @"systemGray3", @"systemGray4", @"systemGray5", @"systemGray6",
        @"label", @"secondaryLabel", @"tertiaryLabel", @"quaternaryLabel", @"placeholderText", @"link",
        @"separator", @"opaqueSeparator", @"systemBackground", @"secondarySystemBackground",
        @"tertiarySystemBackground", @"systemGroupedBackground", @"secondarySystemGroupedBackground",
        @"tertiarySystemGroupedBackground", @"systemFill", @"secondarySystemFill", @"tertiarySystemFill",
        @"quaternarySystemFill"
    ];
    NSArray<UIColor *> *colors = @[
        UIColor.systemRedColor, UIColor.systemOrangeColor, UIColor.systemYellowColor, UIColor.systemGreenColor,
        UIColor.systemMintColor, UIColor.systemTealColor, UIColor.systemCyanColor, UIColor.systemBlueColor,
        UIColor.systemIndigoColor, UIColor.systemPurpleColor, UIColor.systemPinkColor, UIColor.systemBrownColor,
        UIColor.systemGrayColor, UIColor.systemGray2Color, UIColor.systemGray3Color, UIColor.systemGray4Color,
        UIColor.systemGray5Color, UIColor.systemGray6Color, UIColor.labelColor, UIColor.secondaryLabelColor,
        UIColor.tertiaryLabelColor, UIColor.quaternaryLabelColor, UIColor.placeholderTextColor, UIColor.linkColor,
        UIColor.separatorColor, UIColor.opaqueSeparatorColor, UIColor.systemBackgroundColor,
        UIColor.secondarySystemBackgroundColor, UIColor.tertiarySystemBackgroundColor,
        UIColor.systemGroupedBackgroundColor, UIColor.secondarySystemGroupedBackgroundColor,
        UIColor.tertiarySystemGroupedBackgroundColor, UIColor.systemFillColor, UIColor.secondarySystemFillColor,
        UIColor.tertiarySystemFillColor, UIColor.quaternarySystemFillColor
    ];
    UITraitCollection *light = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
    UITraitCollection *dark = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];
    for (NSUInteger index = 0; index < colors.count; index++) {
        CGFloat lr, lg, lb, la, dr, dg, db, da;
        [[colors[index] resolvedColorWithTraitCollection:light] getRed:&lr green:&lg blue:&lb alpha:&la];
        [[colors[index] resolvedColorWithTraitCollection:dark] getRed:&dr green:&dg blue:&db alpha:&da];
        printf("TR_COLOR %s light=%.3f,%.3f,%.3f,%.3f dark=%.3f,%.3f,%.3f,%.3f\n",
               names[index].UTF8String, lr, lg, lb, la, dr, dg, db, da);
    }
}

@end
