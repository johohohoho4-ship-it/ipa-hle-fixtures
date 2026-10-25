#import "Controllers.h"
#include <stdarg.h>
#include <stdio.h>

void F12Print(NSString *format, ...) {
    va_list arguments;
    va_start(arguments, format);
    NSString *line = [[NSString alloc] initWithFormat:format arguments:arguments];
    va_end(arguments);
    printf("%s\n", line.UTF8String);
    fflush(stdout);
}

@interface Controls1Controller ()
@property (nonatomic, strong) UILabel *status;
@property (nonatomic, strong) UIButton *configButton;
@property (nonatomic, strong) UILabel *twoLineLabel;
@property (nonatomic, strong) UISwitch *toggle;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UIStepper *stepper;
@property (nonatomic, strong) UISegmentedControl *segments;
@property (nonatomic) BOOL started;
@end

@implementation Controls1Controller

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scroll];
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:scroll.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.trailingAnchor constant:-20],
        [stack.topAnchor constraintEqualToAnchor:scroll.topAnchor constant:12],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.bottomAnchor constant:-20],
        [stack.widthAnchor constraintEqualToAnchor:scroll.widthAnchor constant:-40],
    ]];

    self.status = [[UILabel alloc] init];
    self.status.accessibilityIdentifier = @"f12.status";
    self.status.numberOfLines = 0;
    self.status.text = @"F12_READY";
    [stack addArrangedSubview:self.status];

    self.configButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *configuration = [UIButtonConfiguration filledButtonConfiguration];
    configuration.title = @"Config";
    configuration.subtitle = @"Sub";
    configuration.image = [UIImage systemImageNamed:@"star"];
    configuration.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    self.configButton.configuration = configuration;
    [stack addArrangedSubview:self.configButton];

    self.twoLineLabel = [[UILabel alloc] init];
    self.twoLineLabel.numberOfLines = 2;
    self.twoLineLabel.text = @"Line one\nLine two";
    [stack addArrangedSubview:self.twoLineLabel];

    self.toggle = [[UISwitch alloc] init];
    self.toggle.on = YES;
    [self.toggle addTarget:self action:@selector(switchChanged:)
          forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:self.toggle];

    self.slider = [[UISlider alloc] init];
    self.slider.minimumValue = 0;
    self.slider.maximumValue = 10;
    self.slider.value = 5;
    [self.slider addTarget:self action:@selector(sliderChanged:)
          forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:self.slider];

    self.stepper = [[UIStepper alloc] init];
    self.stepper.minimumValue = 0;
    self.stepper.maximumValue = 10;
    self.stepper.stepValue = 2;
    self.stepper.value = 4;
    [self.stepper addTarget:self action:@selector(stepperChanged:)
           forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:self.stepper];

    self.segments = [[UISegmentedControl alloc] initWithItems:@[@"A", @"B", @"C"]];
    self.segments.selectedSegmentIndex = 1;
    [self.segments addTarget:self action:@selector(segmentChanged:)
            forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:self.segments];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.started) {
        return;
    }
    self.started = YES;
    UIButtonConfiguration *configuration = self.configButton.configuration;
    F12Print(@"F12_START controls=6");
    F12Print(@"F12_BUTTON title=%@ subtitle=%@ image=%@ corner=%ld",
             configuration.title ?: @"none", configuration.subtitle ?: @"none",
             configuration.image ? @"star" : @"none", (long)configuration.cornerStyle);
    F12Print(@"F12_LABEL text=%@ lines=%ld",
             [self.twoLineLabel.text stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"],
             (long)self.twoLineLabel.numberOfLines);
    F12Print(@"F12_SWITCH on=%d", self.toggle.isOn);
    F12Print(@"F12_SLIDER min=%.1f max=%.1f value=%.1f",
             self.slider.minimumValue, self.slider.maximumValue, self.slider.value);
    F12Print(@"F12_STEPPER min=%.1f max=%.1f step=%.1f value=%.1f",
             self.stepper.minimumValue, self.stepper.maximumValue, self.stepper.stepValue,
             self.stepper.value);
    F12Print(@"F12_SEGMENTS count=%ld selected=%ld",
             (long)self.segments.numberOfSegments, (long)self.segments.selectedSegmentIndex);
    F12Print(@"F12_DONE");
}

- (void)switchChanged:(UISwitch *)toggle {
    self.status.text = [NSString stringWithFormat:@"SWITCH=%d", toggle.isOn];
    F12Print(@"F12_SWITCH_ACTION=%d", toggle.isOn);
}

- (void)sliderChanged:(UISlider *)slider {
    self.status.text = [NSString stringWithFormat:@"SLIDER=%.1f", slider.value];
    F12Print(@"F12_SLIDER_ACTION=%.1f", slider.value);
}

- (void)stepperChanged:(UIStepper *)stepper {
    self.status.text = [NSString stringWithFormat:@"STEPPER=%.1f", stepper.value];
    F12Print(@"F12_STEPPER_ACTION=%.1f", stepper.value);
}

- (void)segmentChanged:(UISegmentedControl *)segments {
    self.status.text = [NSString stringWithFormat:@"SEGMENT=%ld", (long)segments.selectedSegmentIndex];
    F12Print(@"F12_SEGMENT_ACTION=%ld", (long)segments.selectedSegmentIndex);
}

@end
