#import "ViewController.h"
#import <unistd.h>

static void D9Write(NSString *key, NSString *value) {
    NSString *line = [NSString stringWithFormat:@"%@=%@\n", key, value ?: @"missing"];
    NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];
    if (data.length) {
        (void)write(STDOUT_FILENO, data.bytes, data.length);
    }
}

@interface ViewController ()
@property (nonatomic, strong) UILabel *greetingLabel;
@property (nonatomic, strong) UILabel *bundleLabel;
@property (nonatomic, strong) UILabel *displayNameLabel;
@property (nonatomic, strong) UILabel *pluralOneLabel;
@property (nonatomic, strong) UILabel *pluralOtherLabel;
@property (nonatomic, strong) UILabel *localizedImagePathLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    UIStackView *content = [[UIStackView alloc] init];
    content.axis = UILayoutConstraintAxisVertical;
    content.alignment = UIStackViewAlignmentFill;
    content.spacing = 18;
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
    title.accessibilityIdentifier = @"bundle.title";
    title.text = @"Bundle und Lokalisierung";
    title.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
    title.textColor = UIColor.labelColor;
    title.numberOfLines = 0;
    [content addArrangedSubview:title];

    self.greetingLabel = [[UILabel alloc] init];
    self.greetingLabel.accessibilityIdentifier = @"bundle.greeting";
    self.greetingLabel.text = NSLocalizedString(@"fixture.greeting", @"Greeting loaded from Localizable.strings");
    self.greetingLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    self.greetingLabel.textColor = UIColor.labelColor;
    self.greetingLabel.numberOfLines = 0;
    [content addArrangedSubview:self.greetingLabel];

    self.bundleLabel = [[UILabel alloc] init];
    self.bundleLabel.accessibilityIdentifier = @"bundle.identifier";
    self.bundleLabel.text = [NSString stringWithFormat:@"Bundle: %@", NSBundle.mainBundle.bundleIdentifier ?: @"unbekannt"];
    self.bundleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.bundleLabel.textColor = UIColor.secondaryLabelColor;
    self.bundleLabel.numberOfLines = 0;
    [content addArrangedSubview:self.bundleLabel];

    self.displayNameLabel = [[UILabel alloc] init];
    self.displayNameLabel.accessibilityIdentifier = @"bundle.display-name";
    NSString *displayName = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"] ?: @"unbekannt";
    self.displayNameLabel.text = [NSString stringWithFormat:@"Display name: %@", displayName];
    [content addArrangedSubview:self.displayNameLabel];

    NSString *pluralFormat = NSLocalizedString(@"fixture.items", @"Localized plural from Localizable.stringsdict");
    self.pluralOneLabel = [[UILabel alloc] init];
    self.pluralOneLabel.accessibilityIdentifier = @"bundle.plural-one";
    self.pluralOneLabel.text = [NSString localizedStringWithFormat:pluralFormat, 1];
    [content addArrangedSubview:self.pluralOneLabel];

    self.pluralOtherLabel = [[UILabel alloc] init];
    self.pluralOtherLabel.accessibilityIdentifier = @"bundle.plural-other";
    self.pluralOtherLabel.text = [NSString localizedStringWithFormat:pluralFormat, 2];
    [content addArrangedSubview:self.pluralOtherLabel];

    NSString *imagePath = [NSBundle.mainBundle pathForResource:@"LocalizedBadge" ofType:@"png"];
    NSString *imageLocalization = [[imagePath stringByDeletingLastPathComponent] lastPathComponent] ?: @"missing";
    UIImageView *imageView = [[UIImageView alloc] initWithImage:imagePath ? [UIImage imageWithContentsOfFile:imagePath] : nil];
    imageView.accessibilityIdentifier = @"bundle.localized-image";
    imageView.accessibilityLabel = imageLocalization;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [imageView.heightAnchor constraintEqualToConstant:48].active = YES;
    [content addArrangedSubview:imageView];

    self.localizedImagePathLabel = [[UILabel alloc] init];
    self.localizedImagePathLabel.accessibilityIdentifier = @"bundle.localized-image-path";
    self.localizedImagePathLabel.text = [NSString stringWithFormat:@"Image: %@", imageLocalization];
    [content addArrangedSubview:self.localizedImagePathLabel];

    // Report the computed values; exclude the installation-dependent bundle prefix.
    NSString *selectedImage = imagePath ? [NSString stringWithFormat:@"%@/%@", imageLocalization, imagePath.lastPathComponent] : @"missing";
    NSString *greeting = self.greetingLabel.text;
    NSString *singular = self.pluralOneLabel.text;
    NSString *plural = self.pluralOtherLabel.text;
    D9Write(@"D9.greeting", greeting);
    D9Write(@"D9.displayName", displayName);
    D9Write(@"D9.singular", singular);
    D9Write(@"D9.plural", plural);
    D9Write(@"D9.image", selectedImage);

    BOOL german = [greeting isEqualToString:@"Hallo aus dem Bundle."] &&
                  [displayName isEqualToString:@"Lokalisierung"] &&
                  [singular isEqualToString:@"1 Element"] &&
                  [plural isEqualToString:@"2 Elemente"] &&
                  [selectedImage isEqualToString:@"de.lproj/LocalizedBadge.png"];
    BOOL english = [greeting isEqualToString:@"Hello from the bundle."] &&
                   [displayName isEqualToString:@"Localization"] &&
                   [singular isEqualToString:@"1 item"] &&
                   [plural isEqualToString:@"2 items"] &&
                   [selectedImage isEqualToString:@"en.lproj/LocalizedBadge.png"];
    D9Write(@"D9", german || english ? @"ok" : @"FAIL");
}

@end
