#import "ViewController.h"

#import <exception>
#import <stdexcept>
#import <string>
#import <vector>
#include <stdarg.h>
#include <stdio.h>

// C7 fixture: the remaining C++ exception cases of exceptions-2.
// Each case prints one EX2_ line; EX2_DONE closes the run.

static void ex2_line(const char *format, ...) {
    va_list arguments;
    va_start(arguments, format);
    vprintf(format, arguments);
    va_end(arguments);
    printf("\n");
    fflush(stdout);
}

struct A {
    virtual ~A() {}
    int a = 1;
};

struct B {
    virtual ~B() {}
    int b = 7;
};

struct C : A, B {};

struct V {
    int v = 9;
};

struct D : virtual V {};

struct P {
    int p = 3;
};

struct Priv : private P {};

struct X : A {};

struct Y : A {};

struct Z : X, Y {};

static void runtimeError(void) {
    try {
        throw std::runtime_error("boom");
    } catch (const std::exception &error) {
        ex2_line("EX2_RUNTIME=what:%s", error.what());
        return;
    }
    ex2_line("EX2_RUNTIME=not-caught");
}

static void outOfRange(void) {
    std::vector<int> values(2);
    try {
        values.at(5);
    } catch (const std::out_of_range &error) {
        ex2_line("EX2_OUT_OF_RANGE=what:%s", error.what());
        return;
    }
    ex2_line("EX2_OUT_OF_RANGE=not-caught");
}

static void logicError(void) {
    std::vector<int> values(2);
    try {
        values.at(5);
    } catch (const std::logic_error &error) {
        ex2_line("EX2_LOGIC=caught:1 what:%s", error.what());
        return;
    }
    ex2_line("EX2_LOGIC=caught:0");
}

static void multipleInheritance(void) {
    try {
        throw C();
    } catch (const B &base) {
        const C *whole = dynamic_cast<const C *>(&base);
        long offset = whole ? (const char *)&base - (const char *)whole : -1;
        ex2_line("EX2_MULTI=b:%d offset:%ld", base.b, offset);
        return;
    }
    ex2_line("EX2_MULTI=not-caught");
}

static void virtualBase(void) {
    try {
        throw D();
    } catch (const V &base) {
        ex2_line("EX2_VIRTUAL=v:%d", base.v);
        return;
    }
    ex2_line("EX2_VIRTUAL=not-caught");
}

static void privateBase(void) {
    int caught = 0;
    try {
        throw Priv();
    } catch (const P &) {
        caught = 1;
    } catch (...) {
        caught = 0;
    }
    ex2_line("EX2_PRIVATE=caught:%d", caught);
}

static void ambiguousBase(void) {
    int caught = 0;
    try {
        throw Z();
    } catch (const A &) {
        caught = 1;
    } catch (...) {
        caught = 0;
    }
    ex2_line("EX2_AMBIGUOUS=caught:%d", caught);
}

@interface ViewController ()
@property (nonatomic, strong) UILabel *statusLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    UIStackView *content = [[UIStackView alloc] init];
    content.axis = UILayoutConstraintAxisVertical;
    content.alignment = UIStackViewAlignmentCenter;
    content.spacing = 24;
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:content];

    UILabel *title = [[UILabel alloc] init];
    title.accessibilityIdentifier = @"ex2.title";
    title.text = @"Exceptions2 Fixture";
    title.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
    [content addArrangedSubview:title];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.accessibilityIdentifier = @"ex2.status";
    self.statusLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    [content addArrangedSubview:self.statusLabel];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [content.leadingAnchor constraintGreaterThanOrEqualToAnchor:safeArea.leadingAnchor constant:20],
        [content.trailingAnchor constraintLessThanOrEqualToAnchor:safeArea.trailingAnchor constant:-20],
        [content.centerYAnchor constraintEqualToAnchor:safeArea.centerYAnchor]
    ]];

    runtimeError();
    outOfRange();
    logicError();
    multipleInheritance();
    virtualBase();
    privateBase();
    ambiguousBase();
    ex2_line("EX2_DONE");
    self.statusLabel.text = @"EX2_DONE";
}

@end
