#import "ViewController.h"
#import "pthread_basic.h"

@interface ViewController ()
@property (nonatomic, strong) UILabel *resultLabel;
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
    title.accessibilityIdentifier = @"pthread.title";
    title.text = @"POSIX-Threads-Fixture";
    title.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
    title.textColor = UIColor.labelColor;
    title.numberOfLines = 0;
    [content addArrangedSubview:title];

    UILabel *description = [[UILabel alloc] init];
    description.text = @"Zwei Worker, Thread-spezifische Daten und Join in umgekehrter Reihenfolge.";
    description.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    description.textColor = UIColor.secondaryLabelColor;
    description.numberOfLines = 0;
    [content addArrangedSubview:description];

    UIButton *runButton = [UIButton buttonWithType:UIButtonTypeSystem];
    runButton.accessibilityIdentifier = @"pthread.run";
    UIButtonConfiguration *configuration = [UIButtonConfiguration filledButtonConfiguration];
    configuration.title = @"Thread-Ablauf starten";
    runButton.configuration = configuration;
    [runButton.heightAnchor constraintGreaterThanOrEqualToConstant:52].active = YES;
    [runButton addTarget:self action:@selector(runFixture) forControlEvents:UIControlEventTouchUpInside];
    [content addArrangedSubview:runButton];

    self.resultLabel = [[UILabel alloc] init];
    self.resultLabel.accessibilityIdentifier = @"pthread.result";
    self.resultLabel.text = @"Noch nicht gestartet.";
    self.resultLabel.font = [UIFont monospacedSystemFontOfSize:17 weight:UIFontWeightSemibold];
    self.resultLabel.textColor = UIColor.labelColor;
    self.resultLabel.numberOfLines = 0;
    [content addArrangedSubview:self.resultLabel];
}

- (void)runFixture {
    int result = pthread_basic_run();
    self.resultLabel.text = result == 0
        ? @"PTHREAD_OK:17:23"
        : [NSString stringWithFormat:@"PTHREAD_FAIL:exit-%d", result];
}

@end