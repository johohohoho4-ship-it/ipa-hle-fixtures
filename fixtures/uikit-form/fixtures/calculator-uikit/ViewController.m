#import "ViewController.h"
#import <math.h>

@interface ViewController ()
@property (nonatomic, strong) UILabel *displayLabel;
@property (nonatomic, copy) NSString *displayValue;
@property (nonatomic) double storedValue;
@property (nonatomic, copy) NSString *pendingOperator;
@property (nonatomic) BOOL startsNewNumber;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.08 green:0.09 blue:0.11 alpha:1.0];
    self.displayValue = @"0";
    self.startsNewNumber = YES;
    [self buildInterface];
    [self updateDisplay];
}

- (void)buildInterface {
    UIStackView *root = [[UIStackView alloc] init];
    root.axis = UILayoutConstraintAxisVertical;
    root.spacing = 12;
    root.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:root];
    [NSLayoutConstraint activateConstraints:@[
        [root.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:18],
        [root.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-18],
        [root.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:18],
        [root.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-18]
    ]];

    self.displayLabel = [[UILabel alloc] init];
    self.displayLabel.font = [UIFont systemFontOfSize:64 weight:UIFontWeightLight];
    self.displayLabel.textColor = UIColor.whiteColor;
    self.displayLabel.textAlignment = NSTextAlignmentRight;
    self.displayLabel.adjustsFontSizeToFitWidth = YES;
    self.displayLabel.minimumScaleFactor = 0.45;
    self.displayLabel.accessibilityIdentifier = @"calculator.display";
    [root addArrangedSubview:self.displayLabel];
    [self.displayLabel.heightAnchor constraintGreaterThanOrEqualToConstant:110].active = YES;

    NSArray<NSArray<NSString *> *> *rows = @[
        @[@"7", @"8", @"9", @"÷"],
        @[@"4", @"5", @"6", @"×"],
        @[@"1", @"2", @"3", @"−"],
        @[@"C", @"0", @".", @"+"],
        @[@"=", @"=", @"=", @"="]
    ];
    for (NSUInteger rowIndex = 0; rowIndex < 4; rowIndex++) {
        UIStackView *row = [self buttonRowForTitles:rows[rowIndex]];
        [root addArrangedSubview:row];
        [row.heightAnchor constraintEqualToAnchor:root.heightAnchor multiplier:0.145].active = YES;
    }
    UIButton *equalsButton = [self buttonWithTitle:@"=" accent:YES];
    [equalsButton addTarget:self action:@selector(handleButton:) forControlEvents:UIControlEventTouchUpInside];
    [root addArrangedSubview:equalsButton];
    [equalsButton.heightAnchor constraintEqualToAnchor:root.heightAnchor multiplier:0.145].active = YES;
}

- (UIStackView *)buttonRowForTitles:(NSArray<NSString *> *)titles {
    UIStackView *row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.spacing = 10;
    row.distribution = UIStackViewDistributionFillEqually;
    for (NSString *title in titles) {
        BOOL accent = [@[@"÷", @"×", @"−", @"+"] containsObject:title];
        UIButton *button = [self buttonWithTitle:title accent:accent];
        [button addTarget:self action:@selector(handleButton:) forControlEvents:UIControlEventTouchUpInside];
        [row addArrangedSubview:button];
    }
    return row;
}

- (UIButton *)buttonWithTitle:(NSString *)title accent:(BOOL)accent {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.accessibilityIdentifier = [NSString stringWithFormat:@"calculator.button.%@", title];
    button.titleLabel.font = [UIFont systemFontOfSize:30 weight:UIFontWeightMedium];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.backgroundColor = accent ? [UIColor colorWithRed:0.95 green:0.55 blue:0.18 alpha:1.0] : [UIColor colorWithRed:0.19 green:0.20 blue:0.23 alpha:1.0];
    button.layer.cornerRadius = 16;
    return button;
}

- (void)handleButton:(UIButton *)sender {
    NSString *value = sender.currentTitle ?: @"";
    if ([value rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet].location != NSNotFound && value.length == 1) {
        [self enterDigit:value];
    } else if ([value isEqualToString:@"."]) {
        [self enterDecimalPoint];
    } else if ([value isEqualToString:@"C"]) {
        [self clear];
    } else if ([value isEqualToString:@"="]) {
        [self calculate];
    } else {
        [self chooseOperator:value];
    }
    [self updateDisplay];
}

- (void)enterDigit:(NSString *)digit {
    if (self.startsNewNumber || [self.displayValue isEqualToString:@"0"]) {
        self.displayValue = digit;
        self.startsNewNumber = NO;
    } else if (self.displayValue.length < 14) {
        self.displayValue = [self.displayValue stringByAppendingString:digit];
    }
}

- (void)enterDecimalPoint {
    if (self.startsNewNumber) {
        self.displayValue = @"0.";
        self.startsNewNumber = NO;
    } else if ([self.displayValue rangeOfString:@"."].location == NSNotFound) {
        self.displayValue = [self.displayValue stringByAppendingString:@"."];
    }
}

- (void)chooseOperator:(NSString *)operatorSymbol {
    if (self.pendingOperator.length > 0 && !self.startsNewNumber) {
        [self calculate];
    }
    self.storedValue = self.displayValue.doubleValue;
    self.pendingOperator = operatorSymbol;
    self.startsNewNumber = YES;
}

- (void)calculate {
    if (self.pendingOperator.length == 0) return;
    double rightValue = self.displayValue.doubleValue;
    double result = self.storedValue;
    if ([self.pendingOperator isEqualToString:@"+"]) result += rightValue;
    else if ([self.pendingOperator isEqualToString:@"−"]) result -= rightValue;
    else if ([self.pendingOperator isEqualToString:@"×"]) result *= rightValue;
    else if ([self.pendingOperator isEqualToString:@"÷"]) {
        if (rightValue == 0) {
            self.displayValue = @"Error";
            self.pendingOperator = nil;
            self.startsNewNumber = YES;
            return;
        }
        result /= rightValue;
    }
    self.displayValue = [self formattedNumber:result];
    self.storedValue = result;
    self.pendingOperator = nil;
    self.startsNewNumber = YES;
}

- (NSString *)formattedNumber:(double)value {
    if (!isfinite(value)) return @"Error";
    if (fabs(value) < 1e-10) value = 0;
    return [NSString stringWithFormat:@"%.10g", value];
}

- (void)clear {
    self.displayValue = @"0";
    self.storedValue = 0;
    self.pendingOperator = nil;
    self.startsNewNumber = YES;
}

- (void)updateDisplay {
    self.displayLabel.text = self.displayValue ?: @"0";
}

@end


