#import "ViewController.h"

@interface ViewController ()
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic) NSInteger count;
- (NSString *)stackProfileFromArguments;
- (void)installStackProfile:(NSString *)profile;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    NSString *profile = [self stackProfileFromArguments];
    if (profile.length) {
        [self installStackProfile:profile];
        return;
    }

    UIStackView *content = [[UIStackView alloc] init];
    content.axis = UILayoutConstraintAxisVertical;
    content.alignment = UIStackViewAlignmentFill;
    content.spacing = 20;
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:content];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [content.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor constant:24],
        [content.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-24],
        [content.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:32],
        [content.bottomAnchor constraintLessThanOrEqualToAnchor:safeArea.bottomAnchor constant:-24]
    ]];

    UILabel *title = [[UILabel alloc] init];
    title.accessibilityIdentifier = @"layout.title";
    title.text = @"Layout Fixture";
    title.font = [UIFont systemFontOfSize:30 weight:UIFontWeightBold];
    title.textColor = UIColor.labelColor;
    [content addArrangedSubview:title];

    UILabel *collapsed = [[UILabel alloc] init];
    collapsed.accessibilityIdentifier = @"layout.hidden";
    collapsed.text = @"This arranged slot is hidden";
    [content addArrangedSubview:collapsed];
    collapsed.hidden = YES;

    UILabel *description = [[UILabel alloc] init];
    description.accessibilityIdentifier = @"layout.description";
    description.text = @"UIStackView, Safe Area und Auto Layout";
    description.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    description.textColor = UIColor.secondaryLabelColor;
    description.numberOfLines = 0;
    [content addArrangedSubview:description];

    UIButton *increment = [UIButton buttonWithType:UIButtonTypeSystem];
    increment.accessibilityIdentifier = @"layout.increment";
    UIButtonConfiguration *configuration = [UIButtonConfiguration filledButtonConfiguration];
    configuration.title = @"Schritt hinzufügen";
    increment.configuration = configuration;
    [increment.heightAnchor constraintGreaterThanOrEqualToConstant:52].active = YES;
    [increment addTarget:self action:@selector(incrementCount) forControlEvents:UIControlEventTouchUpInside];
    [content addArrangedSubview:increment];

    self.countLabel = [[UILabel alloc] init];
    self.countLabel.accessibilityIdentifier = @"layout.count";
    self.countLabel.text = @"Anzahl: 0";
    self.countLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    self.countLabel.textColor = UIColor.labelColor;
    [content addArrangedSubview:self.countLabel];
}

- (NSString *)stackProfileFromArguments {
    NSString *prefix = @"--stack-profile=";
    for (NSString *argument in NSProcessInfo.processInfo.arguments) {
        if ([argument hasPrefix:prefix]) {
            return [argument substringFromIndex:prefix.length];
        }
    }
    return nil;
}

- (void)installStackProfile:(NSString *)profile {
    BOOL vertical = [profile hasSuffix:@"-vertical"];
    UIStackView *stack = [[UIStackView alloc] init];
    stack.accessibilityIdentifier = @"profile.stack";
    stack.axis = vertical ? UILayoutConstraintAxisVertical : UILayoutConstraintAxisHorizontal;
    stack.alignment = vertical ? UIStackViewAlignmentLeading : UIStackViewAlignmentCenter;
    if ([profile isEqualToString:@"first-baseline-horizontal"]) {
        stack.alignment = UIStackViewAlignmentFirstBaseline;
    } else if ([profile isEqualToString:@"last-baseline-horizontal"]) {
        stack.alignment = UIStackViewAlignmentLastBaseline;
    }
    stack.spacing = [profile isEqualToString:@"negative-spacing-horizontal"] ? -8 : 8;
    stack.translatesAutoresizingMaskIntoConstraints = NO;

    if ([profile hasPrefix:@"fill-equally-"]) {
        stack.distribution = UIStackViewDistributionFillEqually;
    } else if ([profile hasPrefix:@"fill-proportionally-"]) {
        stack.distribution = UIStackViewDistributionFillProportionally;
    } else if ([profile hasPrefix:@"equal-spacing-"]) {
        stack.distribution = UIStackViewDistributionEqualSpacing;
    } else if ([profile hasPrefix:@"equal-centering-"]) {
        stack.distribution = UIStackViewDistributionEqualCentering;
    } else if ([profile hasPrefix:@"first-baseline-"] || [profile hasPrefix:@"last-baseline-"]) {
        stack.distribution = UIStackViewDistributionEqualSpacing;
    } else {
        stack.distribution = UIStackViewDistributionFill;
    }

    [self.view addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-20],
        [stack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:100],
        [stack.heightAnchor constraintEqualToConstant:(vertical ? 240.0 : 160.0)]
    ]];

    NSArray<NSString *> *titles = @[@"A", @"Medium label", @"Last arranged view"];
    NSArray<NSNumber *> *sizes = @[@12, @24, @36];
    if ([profile isEqualToString:@"equal-centering-single-horizontal"]) {
        titles = @[@"Only arranged view"];
        sizes = @[@20];
    }
    for (NSUInteger index = 0; index < titles.count; index++) {
        UILabel *label = [[UILabel alloc] init];
        label.isAccessibilityElement = YES;
        label.accessibilityIdentifier = [NSString stringWithFormat:@"profile.item%lu", (unsigned long)index];
        label.text = titles[index];
        if ([profile isEqualToString:@"last-baseline-horizontal"] && index == 0) {
            label.text = @"First line\nSecond line";
            label.numberOfLines = 0;
        }
        label.font = [UIFont systemFontOfSize:sizes[index].doubleValue];
        [stack addArrangedSubview:label];
        if ([profile isEqualToString:@"hidden-horizontal"] && index == 1) {
            label.hidden = YES;
        }
    }
}

- (void)incrementCount {
    self.count += 1;
    self.countLabel.text = [NSString stringWithFormat:@"Anzahl: %ld", (long)self.count];
}

@end
