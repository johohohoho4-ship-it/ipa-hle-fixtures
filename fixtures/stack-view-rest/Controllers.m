#import "Controllers.h"
#include <stdarg.h>
#include <stdio.h>

void SVPrint(NSString *format, ...) {
    va_list arguments;
    va_start(arguments, format);
    NSString *line = [[NSString alloc] initWithFormat:format arguments:arguments];
    va_end(arguments);
    printf("%s\n", line.UTF8String);
    fflush(stdout);
}

@interface StackViewController ()
@property (nonatomic, strong) UILabel *status;
@property (nonatomic, strong) UIStackView *stack;
@property (nonatomic, strong) UILabel *first;
@property (nonatomic, strong) UILabel *second;
@property (nonatomic, strong) UILabel *third;
@property (nonatomic) BOOL ran;
@end

@implementation StackViewController

- (UILabel *)label:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    return label;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    self.status = [[UILabel alloc] init];
    self.status.accessibilityIdentifier = @"sv.status";
    self.status.numberOfLines = 0;
    self.status.text = @"SV_READY";
    self.status.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.status];

    self.first = [self label:@"A"];
    self.second = [self label:@"B"];
    self.third = [self label:@"C"];
    self.stack = [[UIStackView alloc] initWithArrangedSubviews:@[self.first, self.second, self.third]];
    self.stack.axis = UILayoutConstraintAxisVertical;
    self.stack.distribution = UIStackViewDistributionFill;
    self.stack.alignment = UIStackViewAlignmentLeading;
    self.stack.spacing = 8;
    self.stack.baselineRelativeArrangement = YES;
    self.stack.layoutMarginsRelativeArrangement = YES;
    self.stack.layoutMargins = UIEdgeInsetsMake(10, 10, 10, 10);
    [self.stack setCustomSpacing:12 afterView:self.second];
    self.stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.stack];

    [NSLayoutConstraint activateConstraints:@[
        [self.status.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:20],
        [self.status.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
        [self.status.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-20],
        [self.stack.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:20],
        [self.stack.topAnchor constraintEqualToAnchor:self.status.bottomAnchor constant:20],
        [self.stack.widthAnchor constraintEqualToConstant:200],
    ]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.ran) {
        return;
    }
    self.ran = YES;
    SVPrint(@"SV_START arranged=%lu axis=%ld distribution=%ld alignment=%ld spacing=%.1f baseline=%d margins=%d",
            (unsigned long)self.stack.arrangedSubviews.count,
            (long)self.stack.axis, (long)self.stack.distribution, (long)self.stack.alignment,
            self.stack.spacing, self.stack.isBaselineRelativeArrangement,
            self.stack.isLayoutMarginsRelativeArrangement);
    SVPrint(@"SV_CUSTOM=afterB=%.1f", [self.stack customSpacingAfterView:self.second]);
    [self.stack removeArrangedSubview:self.second];
    SVPrint(@"SV_REMOVE arranged=%lu subviews=%lu removedSuperview=%d",
            (unsigned long)self.stack.arrangedSubviews.count,
            (unsigned long)self.stack.subviews.count, self.second.superview != nil);
    SVPrint(@"SV_DONE");
    self.status.text = @"SV_DONE";
}

@end
