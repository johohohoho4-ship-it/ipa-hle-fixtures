#import "ViewControllers.h"
#include <stdio.h>

// F5 reference: a UITableViewController that is decoded from Main.storyboard. Measured are the
// coder defaults of the decoded tableView, the prototype cell class with its two outlets, the
// order of initWithCoder/awakeFromNib/viewDidLoad, the data source calls for exactly two rows,
// the geometry after layout and a real tap that rewrites the detail label of the tapped cell.

static int gSeq = 0;

static const char *str(NSString *value) { return value ? value.UTF8String : "nil"; }

static NSString *rectStr(CGRect r) {
    return [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", r.origin.x, r.origin.y, r.size.width, r.size.height];
}

static NSString *rgbaStr(UIColor *c) {
    if (!c) return @"nil";
    CGFloat r = 0, g = 0, b = 0, a = 0;
    if (![c getRed:&r green:&g blue:&b alpha:&a]) return @"unconvertible";
    return [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", r, g, b, a];
}

@implementation TableCell

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        printf("SBT_CELL initcoder seq=%d class=%s reuse=%s\n", ++gSeq,
               object_getClassName(self), str(self.reuseIdentifier));
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    printf("SBT_CELL awake seq=%d reuse=%s selection=%ld indentation=%.1f content=%s title=%s detail=%s titleText=%s detailText=%s\n",
           ++gSeq, str(self.reuseIdentifier), (long)self.selectionStyle, self.indentationWidth,
           rectStr(self.contentView.frame).UTF8String, rectStr(self.titleLabel.frame).UTF8String,
           rectStr(self.detailLabel.frame).UTF8String, str(self.titleLabel.text), str(self.detailLabel.text));
}

@end

@implementation TableSceneController

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        printf("SBT_VC initcoder seq=%d class=%s\n", ++gSeq, object_getClassName(self));
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    printf("SBT_VC awake seq=%d tableView=%s\n", ++gSeq, object_getClassName(self.tableView));
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UITableView *table = self.tableView;
    printf("SBT_VIEW didload seq=%d class=%s style=%ld rowHeight=%.3f estimated=%.3f header=%.3f footer=%.3f separator=%ld sepInset=%.1f,%.1f,%.1f,%.1f allowsSelection=%d adjust=%ld background=%s dataSource=%s delegate=%s bounces=%d\n",
           ++gSeq, object_getClassName(table), (long)table.style, table.rowHeight,
           table.estimatedRowHeight, table.sectionHeaderHeight, table.sectionFooterHeight,
           (long)table.separatorStyle, table.separatorInset.top, table.separatorInset.left,
           table.separatorInset.bottom, table.separatorInset.right, table.allowsSelection,
           (long)table.contentInsetAdjustmentBehavior, rgbaStr(table.backgroundColor).UTF8String,
           object_getClassName(table.dataSource), object_getClassName(table.delegate), table.bounces);
}

#pragma mark - data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    printf("SBT_SRC rows section=%ld count=%ld\n", (long)section, 2L);
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TableCell *cell = (TableCell *)[tableView dequeueReusableCellWithIdentifier:@"SBTCell" forIndexPath:indexPath];
    cell.titleLabel.text = [NSString stringWithFormat:@"Row %ld", (long)indexPath.row + 1];
    cell.detailLabel.text = [NSString stringWithFormat:@"Detail %ld", (long)indexPath.row + 1];
    printf("SBT_SRC cell row=%ld class=%s reuse=%s title=%s detail=%s frame=%s\n",
           (long)indexPath.row, object_getClassName(cell), str(cell.reuseIdentifier),
           str(cell.titleLabel.text), str(cell.detailLabel.text), rectStr(cell.frame).UTF8String);
    return cell;
}

#pragma mark - delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    printf("SBT_DLG will row=%ld class=%s frame=%s\n", (long)indexPath.row,
           object_getClassName(cell), rectStr(cell.frame).UTF8String);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TableCell *cell = (TableCell *)[tableView cellForRowAtIndexPath:indexPath];
    cell.detailLabel.text = [NSString stringWithFormat:@"Selected %ld", (long)indexPath.row + 1];
    printf("SBT_TAP row=%ld selected=%ld detail=%s\n", (long)indexPath.row,
           (long)tableView.indexPathForSelectedRow.row, str(cell.detailLabel.text));

    // Second measurement section (SBTX_*). Only the XCUITest asks for it, with the launch
    // argument -SBTXScene YES; in that run the tap above is also the entry into the second
    // scene. Without the argument the original SBT_ run stays exactly as it was.
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SBTXScene"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            printf("SBTX_EXT instantiate scene=sbtxScene\n");
            UIViewController *scene = [self.storyboard instantiateViewControllerWithIdentifier:@"sbtxScene"];
            scene.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:scene animated:NO completion:nil];
        });
    }
}

#pragma mark - lifecycle

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    UITableView *table = self.tableView;
    printf("SBT_LATE appear seq=%d row0=%s row1=%s content=%.3f,%.3f bounds=%s cells=%lu\n",
           ++gSeq, rectStr([table rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]).UTF8String,
           rectStr([table rectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]]).UTF8String,
           table.contentSize.width, table.contentSize.height, rectStr(table.bounds).UTF8String,
           (unsigned long)table.visibleCells.count);
    for (UITableViewCell *cell in table.visibleCells) {
        printf("SBT_LATE cell class=%s frame=%s title=%s titleFrame=%s detail=%s detailFrame=%s\n",
               object_getClassName(cell), rectStr(cell.frame).UTF8String,
               str(((TableCell *)cell).titleLabel.text), rectStr(((TableCell *)cell).titleLabel.frame).UTF8String,
               str(((TableCell *)cell).detailLabel.text), rectStr(((TableCell *)cell).detailLabel.frame).UTF8String);
    }
    printf("SBT_READY rows=%ld\n", (long)[table numberOfRowsInSection:0]);
}

@end
