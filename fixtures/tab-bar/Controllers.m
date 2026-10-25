#import "Controllers.h"
#include <stdarg.h>
#include <stdio.h>

void TBPrint(NSString *format, ...) {
    va_list arguments;
    va_start(arguments, format);
    NSString *line = [[NSString alloc] initWithFormat:format arguments:arguments];
    va_end(arguments);
    printf("%s\n", line.UTF8String);
    fflush(stdout);
}

@implementation TabController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    UILabel *label = [[UILabel alloc] init];
    label.accessibilityIdentifier = @"tb.status";
    label.numberOfLines = 0;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    NSInteger selected = self.tabBarController ? (NSInteger)self.tabBarController.selectedIndex : 0;
    label.text = [NSString stringWithFormat:@"TB_DONE selected=%ld", (long)selected];
    [self.view addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:20],
        [label.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:40],
        [label.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-20],
    ]];
    self.statusLabel = label;
    TBPrint(@"TB_LOAD name=%@ selected=%ld", self.name ?: @"none", (long)selected);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    TBPrint(@"TB_APPEAR name=%@ selected=%ld", self.name ?: @"none",
            (long)(self.tabBarController ? self.tabBarController.selectedIndex : 0));
}

@end
