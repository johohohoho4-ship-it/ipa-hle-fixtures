#import "Controllers.h"
#include <stdarg.h>
#include <stdio.h>

void F14Print(NSString *format, ...) {
    va_list arguments;
    va_start(arguments, format);
    NSString *line = [[NSString alloc] initWithFormat:format arguments:arguments];
    va_end(arguments);
    printf("%s\n", line.UTF8String);
    fflush(stdout);
}

@interface Controls2Controller () <UIPickerViewDataSource, UIPickerViewDelegate, UISearchBarDelegate>
@property (nonatomic, strong) UILabel *status;
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) UIPickerView *picker;
@property (nonatomic, strong) UIPageControl *page;
@property (nonatomic, strong) UIProgressView *progress;
@property (nonatomic, strong) UIActivityIndicatorView *activity;
@property (nonatomic, strong) UISearchBar *search;
@property (nonatomic) BOOL started;
@end

@implementation Controls2Controller

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
    self.status.accessibilityIdentifier = @"f14.status";
    self.status.numberOfLines = 0;
    self.status.text = @"F14_READY";
    [stack addArrangedSubview:self.status];

    self.datePicker = [[UIDatePicker alloc] init];
    self.datePicker.datePickerMode = UIDatePickerModeDate;
    self.datePicker.date = [NSDate dateWithTimeIntervalSince1970:0];
    [self.datePicker addTarget:self action:@selector(dateChanged:)
              forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:self.datePicker];

    self.picker = [[UIPickerView alloc] init];
    self.picker.dataSource = self;
    self.picker.delegate = self;
    [stack addArrangedSubview:self.picker];

    self.page = [[UIPageControl alloc] init];
    self.page.numberOfPages = 3;
    self.page.currentPage = 1;
    [self.page addTarget:self action:@selector(pageChanged:)
        forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:self.page];

    self.progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progress.progress = 0.4f;
    [stack addArrangedSubview:self.progress];

    self.activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    [self.activity startAnimating];
    [stack addArrangedSubview:self.activity];

    self.search = [[UISearchBar alloc] init];
    self.search.placeholder = @"Search";
    self.search.delegate = self;
    [stack addArrangedSubview:self.search];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.started) {
        return;
    }
    self.started = YES;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    F14Print(@"F14_START controls=6");
    F14Print(@"F14_DATE=%@", [formatter stringFromDate:self.datePicker.date]);
    F14Print(@"F14_PICKER components=%ld rows=%ld,%ld selected=%ld,%ld",
             (long)self.picker.numberOfComponents,
             (long)[self.picker numberOfRowsInComponent:0],
             (long)[self.picker numberOfRowsInComponent:1],
             (long)[self.picker selectedRowInComponent:0],
             (long)[self.picker selectedRowInComponent:1]);
    F14Print(@"F14_PAGE pages=%ld current=%ld",
             (long)self.page.numberOfPages, (long)self.page.currentPage);
    F14Print(@"F14_PROGRESS=%.1f", self.progress.progress);
    F14Print(@"F14_ACTIVITY animating=%d", self.activity.isAnimating);
    F14Print(@"F14_SEARCH placeholder=%@", self.search.placeholder);
    F14Print(@"F14_DONE");
}

- (void)dateChanged:(UIDatePicker *)picker {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    F14Print(@"F14_DATE_ACTION=%@", [formatter stringFromDate:picker.date]);
}

- (void)pageChanged:(UIPageControl *)page {
    F14Print(@"F14_PAGE_ACTION=%ld", (long)page.currentPage);
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.status.text = [NSString stringWithFormat:@"SEARCH=%@", searchText];
    F14Print(@"F14_SEARCH_ACTION=%@", searchText);
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return component == 0 ? 3 : 2;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row
            forComponent:(NSInteger)component {
    return [NSString stringWithFormat:@"%@%ld", component == 0 ? @"A" : @"B", (long)row + 1];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component {
    F14Print(@"F14_PICKER_ACTION component=%ld row=%ld", (long)component, (long)row);
}

@end
