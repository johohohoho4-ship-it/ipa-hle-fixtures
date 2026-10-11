#import "ViewController.h"

#import <string.h>
#import <unistd.h>

// C7 fixture: Objective-C and C++ exceptions thrown, unwound and caught.
// Each case prints "<name>: OK|FAIL" via write(1, ...); the label shows EXCEPTIONS_OK when all pass.

static void write_line(const char *line) {
    (void)write(STDOUT_FILENO, line, strlen(line));
    (void)write(STDOUT_FILENO, "\n", 1);
}

static int sCleanups;

struct Guard {
    int *counter;
    explicit Guard(int *c) : counter(c) {}
    ~Guard() { (*counter)++; }
};

struct BaseError {
    virtual ~BaseError() {}
    virtual int code() const { return 1; }
};

struct DerivedError : BaseError {
    int value;
    explicit DerivedError(int v) : value(v) {}
    int code() const override { return value; }
};

__attribute__((noinline)) static void throwNSException(void) {
    @throw [NSException exceptionWithName:@"FixtureError" reason:@"expected" userInfo:nil];
}

__attribute__((noinline)) static void throwThroughCxxFrame(void) {
    Guard guard(&sCleanups);          // must be destroyed while the ObjC exception passes
    throwNSException();
}

__attribute__((noinline)) static void throwInt(void) {
    Guard guard(&sCleanups);
    throw 42;
}

__attribute__((noinline)) static void throwDerived(void) {
    throw DerivedError(7);
}

static BOOL objcCatchByClass(void) {
    @try {
        throwNSException();
    } @catch (NSString *wrong) {
        return NO;
    } @catch (NSException *e) {
        return [e.name isEqualToString:@"FixtureError"] && [e.reason isEqualToString:@"expected"];
    }
    return NO;
}

static BOOL objcFinallyAndRethrow(void) {
    int finallyRuns = 0;
    BOOL innerCaught = NO;
    @try {
        @try {
            @try {
                throwNSException();
            } @finally {
                finallyRuns++;
            }
        } @catch (NSException *e) {
            innerCaught = YES;
            @throw;
        }
    } @catch (id any) {
        return innerCaught && finallyRuns == 1 && [any isKindOfClass:[NSException class]];
    }
    return NO;
}

static BOOL objcThroughCxxDestructor(void) {
    sCleanups = 0;
    @try {
        throwThroughCxxFrame();
    } @catch (NSException *e) {
        return sCleanups == 1;
    }
    return NO;
}

static BOOL cxxCatchByType(void) {
    sCleanups = 0;
    try {
        throwInt();
    } catch (double) {
        return NO;
    } catch (int value) {
        return value == 42 && sCleanups == 1;
    }
    return NO;
}

static BOOL cxxCatchBaseClass(void) {
    try {
        throwDerived();
    } catch (const BaseError &error) {
        return error.code() == 7;
    }
    return NO;
}

static BOOL cxxRethrow(void) {
    try {
        try {
            throwInt();
        } catch (int) {
            throw;
        }
    } catch (...) {
        return YES;
    }
    return NO;
}

static BOOL runAll(void) {
    struct { const char *name; BOOL (*run)(void); } cases[] = {
        {"objc catch by class", objcCatchByClass},
        {"objc finally and rethrow", objcFinallyAndRethrow},
        {"objc through C++ destructor", objcThroughCxxDestructor},
        {"c++ catch by type", cxxCatchByType},
        {"c++ catch base class", cxxCatchBaseClass},
        {"c++ rethrow", cxxRethrow},
    };
    BOOL passed = YES;
    char line[96];
    for (size_t i = 0; i < sizeof(cases) / sizeof(cases[0]); i++) {
        BOOL ok = cases[i].run();
        snprintf(line, sizeof(line), "%s: %s", cases[i].name, ok ? "OK" : "FAIL");
        write_line(line);
        passed = passed && ok;
    }
    write_line(passed ? "EXCEPTIONS_OK" : "EXCEPTIONS_FAIL");
    return passed;
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
    title.accessibilityIdentifier = @"exceptions.title";
    title.text = @"Exceptions Fixture";
    title.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
    [content addArrangedSubview:title];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.accessibilityIdentifier = @"exceptions.status";
    self.statusLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    self.statusLabel.text = runAll() ? @"EXCEPTIONS_OK" : @"EXCEPTIONS_FAIL";
    [content addArrangedSubview:self.statusLabel];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [content.leadingAnchor constraintGreaterThanOrEqualToAnchor:safeArea.leadingAnchor constant:20],
        [content.trailingAnchor constraintLessThanOrEqualToAnchor:safeArea.trailingAnchor constant:-20],
        [content.centerYAnchor constraintEqualToAnchor:safeArea.centerYAnchor]
    ]];
}

@end
