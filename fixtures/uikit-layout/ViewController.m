#import "ViewController.h"

@interface ViewController ()
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic) NSInteger count;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;

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

- (void)incrementCount {
    self.count += 1;
    self.countLabel.text = [NSString stringWithFormat:@"Anzahl: %ld", (long)self.count];
}

@end
