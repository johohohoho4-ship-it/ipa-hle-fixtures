#import "ViewController.h"

@interface ViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *nameField;
@property (nonatomic, strong) UISwitch *enthusiasticSwitch;
@property (nonatomic, strong) UILabel *resultLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    [self buildInterface];
}

- (void)buildInterface {
    UIStackView *form = [[UIStackView alloc] init];
    form.axis = UILayoutConstraintAxisVertical;
    form.alignment = UIStackViewAlignmentFill;
    form.spacing = 18;
    form.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:form];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [form.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor constant:24],
        [form.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-24],
        [form.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:28],
        [form.bottomAnchor constraintLessThanOrEqualToAnchor:safeArea.bottomAnchor constant:-24]
    ]];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"UIKit-Formular";
    titleLabel.font = [UIFont systemFontOfSize:32 weight:UIFontWeightBold];
    titleLabel.textColor = UIColor.labelColor;
    titleLabel.numberOfLines = 0;
    [form addArrangedSubview:titleLabel];

    UILabel *hintLabel = [[UILabel alloc] init];
    hintLabel.text = @"Gib einen Namen ein und tippe auf den Button.";
    hintLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    hintLabel.textColor = UIColor.secondaryLabelColor;
    hintLabel.numberOfLines = 0;
    [form addArrangedSubview:hintLabel];

    self.nameField = [[UITextField alloc] init];
    self.nameField.accessibilityIdentifier = @"uikitForm.name";
    self.nameField.borderStyle = UITextBorderStyleRoundedRect;
    self.nameField.placeholder = @"Name";
    self.nameField.returnKeyType = UIReturnKeyDone;
    self.nameField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.nameField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.nameField.delegate = self;
    self.nameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.nameField.heightAnchor constraintGreaterThanOrEqualToConstant:48].active = YES;
    [form addArrangedSubview:self.nameField];

    UILabel *switchLabel = [[UILabel alloc] init];
    switchLabel.text = @"Erweiterte Begrüßung";
    switchLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    switchLabel.textColor = UIColor.labelColor;

    self.enthusiasticSwitch = [[UISwitch alloc] init];
    self.enthusiasticSwitch.accessibilityIdentifier = @"uikitForm.enthusiastic";
    self.enthusiasticSwitch.on = NO;
    UIStackView *switchRow = [[UIStackView alloc] initWithArrangedSubviews:@[switchLabel, self.enthusiasticSwitch]];
    switchRow.axis = UILayoutConstraintAxisHorizontal;
    switchRow.alignment = UIStackViewAlignmentCenter;
    switchRow.distribution = UIStackViewDistributionEqualSpacing;
    [form addArrangedSubview:switchRow];

    UIButton *greetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    greetButton.accessibilityIdentifier = @"uikitForm.submit";
    UIButtonConfiguration *buttonConfiguration = [UIButtonConfiguration filledButtonConfiguration];
    buttonConfiguration.title = @"Begrüßung anzeigen";
    buttonConfiguration.cornerStyle = UIButtonConfigurationCornerStyleMedium;
    greetButton.configuration = buttonConfiguration;
    [greetButton addTarget:self action:@selector(showGreeting) forControlEvents:UIControlEventTouchUpInside];
    [greetButton.heightAnchor constraintGreaterThanOrEqualToConstant:50].active = YES;
    [form addArrangedSubview:greetButton];

    self.resultLabel = [[UILabel alloc] init];
    self.resultLabel.accessibilityIdentifier = @"uikitForm.result";
    self.resultLabel.text = @"Noch nichts übernommen.";
    self.resultLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
    self.resultLabel.textColor = UIColor.labelColor;
    self.resultLabel.numberOfLines = 0;
    [form addArrangedSubview:self.resultLabel];
}

- (void)showGreeting {
    NSString *name = [self.nameField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (name.length == 0) {
        name = @"Welt";
    }

    if (self.enthusiasticSwitch.isOn) {
        self.resultLabel.text = [NSString stringWithFormat:@"Hallo, %@! Schön, dass du da bist.", name];
    } else {
        self.resultLabel.text = [NSString stringWithFormat:@"Hallo, %@!", name];
    }
    [self.view endEditing:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end