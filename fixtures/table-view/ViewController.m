#import "ViewController.h"
#include <stdio.h>

// F10 reference: a plain UITableView with a registered system cell class, a one-section data source of
// `rows` rows and a delegate that only reports display and selection. Every line is TBL_*; the HLE
// replays the same app and must print the same lines (call order, geometry, reuse, selection, deletion).

static NSString *const kCell = @"cell";

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong) UITableView *table;
@property(nonatomic, strong) UILabel *status;
@property(nonatomic) NSInteger rows;
@property(nonatomic) NSInteger step;
@property(nonatomic) BOOL logCalls;
@end

@implementation ViewController

static NSString *rect(CGRect r) { return [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", r.origin.x, r.origin.y, r.size.width, r.size.height]; }
static NSString *rgba(UIColor *c) {
    if (!c) return @"nil";
    CGFloat r = 0, g = 0, b = 0, a = 0;
    [c getRed:&r green:&g blue:&b alpha:&a];
    return [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", r, g, b, a];
}

- (void)state:(NSString *)phase {
    NSMutableArray *visible = [NSMutableArray array];
    for (NSIndexPath *p in [self.table indexPathsForVisibleRows]) [visible addObject:@(p.row)];
    printf("TBL_STATE phase=%s offset=%.3f,%.3f size=%.3f,%.3f bounds=%s visible=%s cells=%lu subviews=%lu\n", phase.UTF8String,
           self.table.contentOffset.x, self.table.contentOffset.y, self.table.contentSize.width, self.table.contentSize.height,
           rect(self.table.bounds).UTF8String, [visible componentsJoinedByString:@","].UTF8String,
           (unsigned long)self.table.visibleCells.count, (unsigned long)self.table.subviews.count);
}

- (void)cellGeometry:(NSInteger)row {
    UITableViewCell *cell = [self.table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    if (!cell) { printf("TBL_CELL row=%ld none\n", (long)row); return; }
    UILabel *label = cell.textLabel;
    printf("TBL_CELL row=%ld frame=%s content=%s label=%s text=%s font=%.3f color=%s background=%s selectedBackground=%s reuse=%s subviews=%lu\n",
           (long)row, rect(cell.frame).UTF8String, rect(cell.contentView.frame).UTF8String, rect(label.frame).UTF8String,
           label.text.UTF8String, label.font.pointSize, rgba(label.textColor).UTF8String, rgba(cell.backgroundColor).UTF8String,
           rgba(cell.selectedBackgroundView.backgroundColor).UTF8String, cell.reuseIdentifier.UTF8String,
           (unsigned long)cell.subviews.count);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.rows = 1000;
    self.table = [[UITableView alloc] initWithFrame:CGRectMake(20, 100, 350, 300) style:UITableViewStylePlain];
    self.table.accessibilityIdentifier = @"table.view";
    printf("TBL_CONFIG style=%ld bounces=%d adjust=%ld rowHeight=%.3f headerHeight=%.3f footerHeight=%.3f estimated=%.3f separator=%ld separatorInset=%.3f,%.3f,%.3f,%.3f allowsSelection=%d background=%s\n",
           (long)self.table.style, self.table.bounces, (long)self.table.contentInsetAdjustmentBehavior, self.table.rowHeight,
           self.table.sectionHeaderHeight, self.table.sectionFooterHeight, self.table.estimatedRowHeight,
           (long)self.table.separatorStyle, self.table.separatorInset.top, self.table.separatorInset.left,
           self.table.separatorInset.bottom, self.table.separatorInset.right, self.table.allowsSelection,
           rgba(self.table.backgroundColor).UTF8String);
    self.table.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    self.table.bounces = NO;
    self.table.dataSource = self;
    self.table.delegate = self;
    [self.table registerClass:[UITableViewCell class] forCellReuseIdentifier:kCell];
    [self.view addSubview:self.table];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(40, 420, 220, 45);
    [button setTitle:@"Advance" forState:UIControlStateNormal];
    button.accessibilityIdentifier = @"table.advance";
    [button addTarget:self action:@selector(advance:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    self.status = [[UILabel alloc] initWithFrame:CGRectMake(30, 480, 330, 45)];
    self.status.text = @"Ready";
    self.status.accessibilityIdentifier = @"table.status";
    [self.view addSubview:self.status];
}

- (void)advance:(UIButton *)sender {
    self.step++;
    printf("TBL_BEFORE step=%ld\n", (long)self.step);
    self.logCalls = YES;
    if (self.step == 1) {                                   // first load
        [self.table reloadData];
        [self.table layoutIfNeeded];
        [self state:@"loaded"];
        for (NSInteger row = 0; row < 3; row++) [self cellGeometry:row];
        printf("TBL_RECT header=%s row0=%s row1=%s row6=%s\n", rect([self.table rectForHeaderInSection:0]).UTF8String,
               rect([self.table rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]).UTF8String,
               rect([self.table rectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]]).UTF8String,
               rect([self.table rectForRowAtIndexPath:[NSIndexPath indexPathForRow:6 inSection:0]]).UTF8String);
    } else if (self.step == 2) {                            // scroll: new rows in, old cells reused
        NSMutableArray *before = [NSMutableArray array];
        for (UITableViewCell *cell in self.table.visibleCells) [before addObject:@((NSUInteger)cell)];
        self.table.contentOffset = CGPointMake(0, 400);
        [self.table layoutIfNeeded];
        [self state:@"scrolled"];
        NSUInteger reused = 0;
        for (UITableViewCell *cell in self.table.visibleCells) reused += [before containsObject:@((NSUInteger)cell)];
        printf("TBL_REUSE reused=%lu of=%lu\n", (unsigned long)reused, (unsigned long)self.table.visibleCells.count);
        [self cellGeometry:10];
    } else if (self.step == 3) {                            // programmatic selection
        NSIndexPath *path = [NSIndexPath indexPathForRow:11 inSection:0];
        [self.table selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
        printf("TBL_SELECT selected=%ld\n", (long)self.table.indexPathForSelectedRow.row);
        [self cellGeometry:11];
        [self.table deselectRowAtIndexPath:path animated:NO];
        printf("TBL_SELECT selected=%d\n", self.table.indexPathForSelectedRow != nil);
    } else if (self.step == 4) {                            // scroll positions
        NSIndexPath *path = [NSIndexPath indexPathForRow:50 inSection:0];
        UITableViewScrollPosition positions[] = {UITableViewScrollPositionTop, UITableViewScrollPositionMiddle,
                                                 UITableViewScrollPositionBottom, UITableViewScrollPositionNone};
        const char *names[] = {"top", "middle", "bottom", "none"};
        for (int i = 0; i < 4; i++) {
            self.table.contentOffset = CGPointMake(0, 0);
            [self.table scrollToRowAtIndexPath:path atScrollPosition:positions[i] animated:NO];
            [self.table layoutIfNeeded];
            printf("TBL_SCROLLTO position=%s offset=%.3f\n", names[i], self.table.contentOffset.y);
        }
        self.table.contentOffset = CGPointMake(0, 0);
        [self.table layoutIfNeeded];
    } else if (self.step == 5) {                            // deletion without animation
        NSMutableArray *before = [NSMutableArray array];
        for (NSInteger row = 1; row <= 4; row++)
            [before addObject:@((NSUInteger)[self.table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]])];
        self.rows = 999;
        [self.table deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [self.table layoutIfNeeded];
        [self state:@"deleted"];
        for (NSInteger row = 1; row <= 3; row++) {
            UITableViewCell *cell = [self.table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
            printf("TBL_KEEP row=%ld same_as_old_row=%ld\n", (long)row, (long)[before indexOfObject:@((NSUInteger)cell)]);
        }
        [self cellGeometry:2];
    }
    self.logCalls = NO;
    printf("TBL_AFTER step=%ld\n", (long)self.step);
    self.status.text = [NSString stringWithFormat:@"Done %ld", (long)self.step];
}

#pragma mark - data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.logCalls) printf("TBL_SRC numberOfSections\n");
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.logCalls) printf("TBL_SRC rows section=%ld count=%ld\n", (long)section, (long)self.rows);
    return self.rows;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.logCalls) printf("TBL_SRC title section=%ld\n", (long)section);
    return @"Header";
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCell forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"Row %ld", (long)indexPath.row];
    if (self.logCalls) printf("TBL_SRC cell row=%ld\n", (long)indexPath.row);
    return cell;
}

#pragma mark - delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.logCalls) printf("TBL_DLG will row=%ld\n", (long)indexPath.row);
}
- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.logCalls) printf("TBL_DLG end row=%ld\n", (long)indexPath.row);
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    printf("TBL_DLG select row=%ld selected=%ld\n", (long)indexPath.row, (long)tableView.indexPathForSelectedRow.row);
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    printf("TBL_TAP background=%s\n", rgba(cell.selectedBackgroundView.backgroundColor).UTF8String);
    self.status.text = [NSString stringWithFormat:@"Selected %ld", (long)indexPath.row];
}

@end
