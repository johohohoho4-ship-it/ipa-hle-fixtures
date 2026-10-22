#import "ViewController.h"
#import "sync_stress.h"
#import <pthread.h>

static ViewController *gRunner;

static void *run_stress(void *unused) {
    (void)unused;
    int code = sync_stress_run();
    // The stress blocks while its workers run; report from the main queue so the
    // UI (and an HLE session) stays responsive.
    dispatch_async(dispatch_get_main_queue(), ^{
        [gRunner showResult:code];
    });
    return 0;
}

@interface ViewController ()
@property (nonatomic, strong) UILabel *resultLabel;
- (void)showResult:(int)code;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    gRunner = self;
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
    title.accessibilityIdentifier = @"sync.title";
    title.text = @"Synchronisations-Stress (C2)";
    title.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
    title.textColor = UIColor.labelColor;
    title.numberOfLines = 0;
    [content addArrangedSubview:title];

    UILabel *description = [[UILabel alloc] init];
    description.text = @"Vier Worker (Mutex, unfair lock, Atomics), Ringpuffer mit zwei Condition Variables und ein ablaufender Semaphore-Timeout.";
    description.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    description.textColor = UIColor.secondaryLabelColor;
    description.numberOfLines = 0;
    [content addArrangedSubview:description];

    UIButton *runButton = [UIButton buttonWithType:UIButtonTypeSystem];
    runButton.accessibilityIdentifier = @"sync.run";
    UIButtonConfiguration *configuration = [UIButtonConfiguration filledButtonConfiguration];
    configuration.title = @"Stress starten";
    runButton.configuration = configuration;
    [runButton.heightAnchor constraintGreaterThanOrEqualToConstant:52].active = YES;
    [runButton addTarget:self action:@selector(runFixture) forControlEvents:UIControlEventTouchUpInside];
    [content addArrangedSubview:runButton];

    self.resultLabel = [[UILabel alloc] init];
    self.resultLabel.accessibilityIdentifier = @"sync.result";
    self.resultLabel.text = @"Noch nicht gestartet.";
    self.resultLabel.font = [UIFont monospacedSystemFontOfSize:17 weight:UIFontWeightSemibold];
    self.resultLabel.textColor = UIColor.labelColor;
    self.resultLabel.numberOfLines = 0;
    [content addArrangedSubview:self.resultLabel];
}

- (void)runFixture {
    self.resultLabel.text = @"Läuft …";
    pthread_t thread;
    if (pthread_create(&thread, NULL, run_stress, NULL) == 0) {
        pthread_detach(thread);
    } else {
        self.resultLabel.text = @"SYNC_FAIL:exit-30";
    }
}

- (void)showResult:(int)code {
    self.resultLabel.text = code == 0
        ? @"SYNC_OK:8000:125250"
        : [NSString stringWithFormat:@"SYNC_FAIL:exit-%d", code];
}

@end
