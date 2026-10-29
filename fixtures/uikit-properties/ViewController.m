#import "ViewController.h"
#include <stdio.h>

// F5 measurement fixture: reads framework getters the F5 decoder has to resolve. The button
// `props.run` runs every measurement once, after the view hierarchy is laid out, and prints one
// line per read. Nothing here asserts an expected value; every line is what the simulator
// returned in that state. Prefixes: GET_ (framework properties) and TBLF_ (table header/footer).
//
// Conventions used by the lines:
//   same=<0/1>  pointer identity with the object handed to the setter in that state; for the
//               `init` and `nil` states it compares against nil (so it repeats the nil flag).
//   nil=<0/1>   the getter returned nil.
//   rgba=...    result of -[UIColor getRed:green:blue:alpha:] as %.3f,%.3f,%.3f,%.3f; "nil" when
//               the color is nil and "n/a" when the color cannot be converted to RGB.

static NSString *const kCell = @"props.cell";

@interface ViewController () <UITableViewDataSource>
@property(nonatomic, strong) UITableView *table;
@property(nonatomic, strong) UILabel *status;
@property(nonatomic) BOOL measured;
@end

@implementation ViewController

static const char *flag(BOOL value) { return value ? "1" : "0"; }
static const char *sstr(NSString *value) { return value ? value.UTF8String : "nil"; }

static NSString *rgba(UIColor *color) {
    if (!color) return @"nil";
    CGFloat r = 0, g = 0, b = 0, a = 0;
    if (![color getRed:&r green:&g blue:&b alpha:&a]) return @"n/a";
    return [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", r, g, b, a];
}

static NSString *frameString(UIView *view) {
    return view ? NSStringFromCGRect(view.frame) : @"none";
}

static NSString *rectString(CGRect rect) { return NSStringFromCGRect(rect); }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;

    // 350x300 table on the root view; four plain rows so row 0 exists and stays visible.
    self.table = [[UITableView alloc] initWithFrame:CGRectMake(20, 60, 350, 300) style:UITableViewStylePlain];
    self.table.accessibilityIdentifier = @"props.table";
    self.table.dataSource = self;
    self.table.rowHeight = 44;
    self.table.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.table registerClass:[UITableViewCell class] forCellReuseIdentifier:kCell];
    [self.view addSubview:self.table];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(20, 380, 350, 45);
    [button setTitle:@"Run" forState:UIControlStateNormal];
    button.accessibilityIdentifier = @"props.run";
    [button addTarget:self action:@selector(runMeasurements:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];

    self.status = [[UILabel alloc] initWithFrame:CGRectMake(20, 440, 350, 45)];
    self.status.text = @"Ready";
    self.status.accessibilityIdentifier = @"props.status";
    [self.view addSubview:self.status];

    printf("GET_CONFIG table_frame=%s row_height=%.3f rows=%ld\n",
           rectString(self.table.frame).UTF8String, self.table.rowHeight,
           (long)[self tableView:self.table numberOfRowsInSection:0]);
}

- (void)runMeasurements:(UIButton *)sender {
    if (self.measured) return;                       // one block per launch keeps the log stable
    self.measured = YES;
    [self.table reloadData];                         // guarantee row 0 exists before it is read
    [self.view layoutIfNeeded];
    [self.table layoutIfNeeded];
    printf("GET_START\n");
    [self measureLabel];
    [self measureTextField];
    [self measureStackView];
    [self measureViewTag];
    [self measureTableHeaderFooter];
    printf("GET_END\n");
    self.status.text = @"DONE";
    printf("GET_STATUS text=%s\n", sstr(self.status.text));
}

#pragma mark - 1. UILabel textColor

- (void)measureLabel {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 160, 21)];

    UIColor *initialColor = label.textColor;
    printf("GET_LABEL stage=init rgba=%s same=%s nil=%s\n", rgba(initialColor).UTF8String,
           flag(initialColor == nil), flag(initialColor == nil));

    UIColor *wanted = [UIColor colorWithRed:0.25 green:0.5 blue:0.75 alpha:1.0];
    label.textColor = wanted;
    UIColor *assigned = label.textColor;
    printf("GET_LABEL stage=set rgba=%s same=%s nil=%s\n", rgba(assigned).UTF8String,
           flag(assigned == wanted), flag(assigned == nil));

    label.textColor = nil;
    UIColor *cleared = label.textColor;
    printf("GET_LABEL stage=nil rgba=%s same=%s nil=%s\n", rgba(cleared).UTF8String,
           flag(cleared == nil), flag(cleared == nil));

    // Same read on the textLabel of a real UITableViewCell that this table created and laid out.
    UITableViewCell *cell = [self.table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    if (!cell) { printf("GET_LABEL stage=cell absent\n"); return; }
    UILabel *cellLabel = cell.textLabel;
    UIColor *cellColor = cellLabel.textColor;
    printf("GET_LABEL stage=cell rgba=%s same=%s nil=%s text=%s label=%s\n",
           rgba(cellColor).UTF8String, flag(cellColor == nil), flag(cellColor == nil),
           sstr(cellLabel.text), flag(cellLabel != nil));
}

#pragma mark - 2. UITextField placeholder and borderStyle

- (void)measureTextField {
    UITextField *field = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];

    NSString *initialPlaceholder = field.placeholder;
    printf("GET_FIELD stage=init placeholder=%s border=%ld\n",
           sstr(initialPlaceholder), (long)field.borderStyle);

    NSString *ada = @"Ada";
    field.placeholder = ada;
    NSString *readPlaceholder = field.placeholder;
    printf("GET_FIELD stage=set placeholder=%s equal=%s same=%s nil=%s border=%ld\n",
           sstr(readPlaceholder), flag([readPlaceholder isEqualToString:ada]),
           flag(readPlaceholder == ada), flag(readPlaceholder == nil), (long)field.borderStyle);

    field.borderStyle = (UITextBorderStyle)3;
    NSString *readAfterBorder = field.placeholder;
    printf("GET_FIELD stage=border placeholder=%s equal=%s same=%s nil=%s border=%ld\n",
           sstr(readAfterBorder), flag([readAfterBorder isEqualToString:ada]),
           flag(readAfterBorder == ada), flag(readAfterBorder == nil), (long)field.borderStyle);

    field.placeholder = nil;
    NSString *clearedPlaceholder = field.placeholder;
    printf("GET_FIELD stage=nil placeholder=%s equal=%s same=%s nil=%s border=%ld\n",
           sstr(clearedPlaceholder), flag([clearedPlaceholder isEqualToString:ada]),
           flag(clearedPlaceholder == nil), flag(clearedPlaceholder == nil), (long)field.borderStyle);
}

#pragma mark - 3. UIStackView

- (void)measureStackView {
    UIStackView *stack = [[UIStackView alloc] initWithFrame:CGRectMake(0, 0, 200, 120)];
    printf("GET_STACK stage=init axis=%ld alignment=%ld distribution=%ld spacing=%.3f arranged=%lu\n",
           (long)stack.axis, (long)stack.alignment, (long)stack.distribution, stack.spacing,
           (unsigned long)stack.arrangedSubviews.count);

    UILabel *first = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
    first.tag = 11;
    first.text = @"A";
    UILabel *second = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
    second.tag = 12;
    second.text = @"B";
    [stack addArrangedSubview:first];
    [stack addArrangedSubview:second];
    printf("GET_STACK stage=added axis=%ld alignment=%ld distribution=%ld spacing=%.3f arranged=%lu\n",
           (long)stack.axis, (long)stack.alignment, (long)stack.distribution, stack.spacing,
           (unsigned long)stack.arrangedSubviews.count);

    stack.axis = (UILayoutConstraintAxis)1;
    stack.alignment = (UIStackViewAlignment)2;
    stack.distribution = (UIStackViewDistribution)3;
    stack.spacing = 7;
    NSArray *arranged = stack.arrangedSubviews;
    NSUInteger count = arranged.count;
    UIView *arrangedFirst = count > 0 ? (UIView *)arranged[0] : nil;
    UIView *arrangedSecond = count > 1 ? (UIView *)arranged[1] : nil;
    long firstTag = arrangedFirst ? (long)arrangedFirst.tag : -1;
    long secondTag = arrangedSecond ? (long)arrangedSecond.tag : -1;
    printf("GET_STACK stage=configured axis=%ld alignment=%ld distribution=%ld spacing=%.3f arranged=%lu tag0=%ld tag1=%ld same0=%s same1=%s\n",
           (long)stack.axis, (long)stack.alignment, (long)stack.distribution, stack.spacing,
           (unsigned long)count, firstTag, secondTag,
           flag(arrangedFirst == first), flag(arrangedSecond == second));

    // Documented behaviour: removeArrangedSubview: drops the arrangement entry but keeps the
    // view in the stack's subviews. Both numbers are measured, not assumed.
    [stack removeArrangedSubview:first];
    NSArray *subviews = stack.subviews;
    printf("GET_STACK stage=removed arranged=%lu contains_first=%s subviews=%lu first_still_subview=%s\n",
           (unsigned long)stack.arrangedSubviews.count,
           flag([stack.arrangedSubviews containsObject:first]),
           (unsigned long)subviews.count, flag([subviews containsObject:first]));
}

#pragma mark - 4. UIView tag

- (void)measureViewTag {
    UIView *parent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    printf("GET_TAG stage=init tag=%ld\n", (long)parent.tag);

    parent.tag = 42;
    printf("GET_TAG stage=set tag=%ld\n", (long)parent.tag);

    UIView *child = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    child.tag = 7;
    [parent addSubview:child];
    printf("GET_TAG stage=child tag=%ld subviews=%lu\n",
           (long)child.tag, (unsigned long)parent.subviews.count);

    UIView *foundChild = [parent viewWithTag:7];
    printf("GET_TAG stage=query tag=7 found=%s same_child=%s\n",
           flag(foundChild != nil), flag(foundChild == child));

    UIView *foundSelf = [parent viewWithTag:42];
    printf("GET_TAG stage=query tag=42 found=%s same_parent=%s\n",
           flag(foundSelf != nil), flag(foundSelf == parent));

    UIView *missing = [parent viewWithTag:99];
    printf("GET_TAG stage=query tag=99 found=%s\n", flag(missing != nil));
}

#pragma mark - 5. UITableView header and footer views

- (void)tableState:(const char *)stage {
    UITableView *table = self.table;
    [table layoutIfNeeded];
    UIView *footer = table.tableFooterView;
    UIView *header = table.tableHeaderView;
    NSIndexPath *row0 = [NSIndexPath indexPathForRow:0 inSection:0];
    printf("TBLF_STATE stage=%s footer=%s footer_super=%s footer_frame=%s header=%s header_super=%s header_frame=%s content=%.3f,%.3f bounds=%s offset=%.3f,%.3f row0=%s sections=%ld cells=%lu\n",
           stage,
           flag(footer != nil), flag(footer != nil && footer.superview == table),
           frameString(footer).UTF8String,
           flag(header != nil), flag(header != nil && header.superview == table),
           frameString(header).UTF8String,
           table.contentSize.width, table.contentSize.height,
           rectString(table.bounds).UTF8String,
           table.contentOffset.x, table.contentOffset.y,
           rectString([table rectForRowAtIndexPath:row0]).UTF8String,
           (long)table.numberOfSections, (unsigned long)table.visibleCells.count);
}

- (void)measureTableHeaderFooter {
    [self tableState:"init"];

    UIView *footer = [[UIView alloc] initWithFrame:CGRectZero];
    self.table.tableFooterView = footer;
    [self.table layoutIfNeeded];
    [self tableState:"footer-zero"];

    footer.frame = CGRectMake(0, 0, 350, 120);
    [self.table layoutIfNeeded];
    [self tableState:"footer-frame"];

    self.table.tableFooterView = nil;
    [self.table layoutIfNeeded];
    [self tableState:"footer-nil"];

    UIView *header = [[UIView alloc] initWithFrame:CGRectZero];
    self.table.tableHeaderView = header;
    [self.table layoutIfNeeded];
    [self tableState:"header-zero"];

    header.frame = CGRectMake(0, 0, 350, 120);
    [self.table layoutIfNeeded];
    [self tableState:"header-frame"];

    self.table.tableHeaderView = nil;
    [self.table layoutIfNeeded];
    [self tableState:"header-nil"];
}

#pragma mark - data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 4; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCell forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"Row %ld", (long)indexPath.row];
    return cell;
}

@end
