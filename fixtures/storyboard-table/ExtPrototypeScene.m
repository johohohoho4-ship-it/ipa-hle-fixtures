#import "ExtPrototypeScene.h"
#include <stdio.h>
#include <objc/runtime.h>

// SBTX_ reference: the prototype cell of the second scene keeps an outlet on an object
// that lives outside the cell nib (the scene controller). Measured are
//   - the cell before its outlets are wired (initWithCoder:), the wiring itself (the
//     property setters, i.e. the moment the external object arrives) and the state after
//     awakeFromNib, each with class and pointer of the external object,
//   - the selection callback that the cell sends through its external outlet,
//   - the built-in textLabel/detailTextLabel profile of an IBUITableViewCellStyleSubtitle
//     cell of the same run (nil vs. object, text, colour, font, frames after layout),
//   - the archive profile (class, reuseIdentifier, contentView subviews) of both cells.
// Every value is printed as measured; nothing is assumed.

static int gSbtxSeq = 0;

static const char *xstr(NSString *value) { return value ? value.UTF8String : "nil"; }

static NSString *xref(id object) {
    if (!object) return @"nil";
    return [NSString stringWithFormat:@"%s@%p", object_getClassName(object), (void *)object];
}

static NSString *xrect(CGRect r) {
    return [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", r.origin.x, r.origin.y, r.size.width, r.size.height];
}

static NSString *xrgba(UIColor *c) {
    if (!c) return @"nil";
    CGFloat r = 0, g = 0, b = 0, a = 0;
    if (![c getRed:&r green:&g blue:&b alpha:&a]) return @"unconvertible";
    return [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", r, g, b, a];
}

static NSString *xfont(UIFont *f) {
    if (!f) return @"nil";
    return [NSString stringWithFormat:@"%s %.1f", f.fontName.UTF8String, f.pointSize];
}

static NSString *xsubviews(UIView *view) {
    NSMutableArray *names = [NSMutableArray array];
    for (UIView *sub in view.subviews) {
        [names addObject:[NSString stringWithUTF8String:object_getClassName(sub)]];
    }
    return [NSString stringWithFormat:@"%lu(%@)", (unsigned long)view.subviews.count,
            names.count ? [names componentsJoinedByString:@","] : @"-"];
}

#pragma mark - cell

@interface ExtOutletCell ()
@property (nonatomic) BOOL firedCallback;
@end

@implementation ExtOutletCell

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        printf("SBTX_CELL init seq=%d class=%s reuse=%s upstream=%s delegate=%s dataSource=%s caption=%s\n",
               ++gSbtxSeq, object_getClassName(self), xstr(self.reuseIdentifier),
               xref(self.upstream).UTF8String, xref(self.delegate).UTF8String,
               xref(self.dataSource).UTF8String, xref(self.captionLabel).UTF8String);
    }
    return self;
}

// The setters are the moment the nib loader applies the archived connections. They run
// after initWithCoder: and before awakeFromNib:, so the external identity is visible here
// for the first time.
- (void)setUpstream:(id<SBTXUpstream>)upstream {
    _upstream = upstream;
    printf("SBTX_CELL outlet seq=%d property=upstream value=%s\n", ++gSbtxSeq, xref(upstream).UTF8String);
}

- (void)setDelegate:(id)delegate {
    _delegate = delegate;
    printf("SBTX_CELL outlet seq=%d property=delegate value=%s\n", ++gSbtxSeq, xref(delegate).UTF8String);
}

- (void)setDataSource:(id)dataSource {
    _dataSource = dataSource;
    printf("SBTX_CELL outlet seq=%d property=dataSource value=%s\n", ++gSbtxSeq, xref(dataSource).UTF8String);
}

- (void)setCaptionLabel:(UILabel *)captionLabel {
    _captionLabel = captionLabel;
    printf("SBTX_CELL outlet seq=%d property=captionLabel value=%s\n", ++gSbtxSeq, xref(captionLabel).UTF8String);
}

- (void)awakeFromNib {
    [super awakeFromNib];
    printf("SBTX_CELL awake seq=%d class=%s reuse=%s upstream=%s delegate=%s dataSource=%s caption=%s captionText=%s content=%s\n",
           ++gSbtxSeq, object_getClassName(self), xstr(self.reuseIdentifier),
           xref(self.upstream).UTF8String, xref(self.delegate).UTF8String,
           xref(self.dataSource).UTF8String, xref(self.captionLabel).UTF8String,
           xstr(self.captionLabel.text), xrect(self.contentView.frame).UTF8String);
}

// A tap selects the cell; the cell then calls the object that the storyboard wired into
// its external outlet. If the outlet stayed nil (or holds an unexpected class) the call is
// skipped and printed instead of being guessed.
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (!selected || self.firedCallback) return;
    self.firedCallback = YES;
    BOOL handled = [self.upstream respondsToSelector:@selector(sbtxCellDidTapWithIdentifier:)];
    printf("SBTX_CALLBACK seq=%d reuse=%s upstream=%s responds=%d\n",
           ++gSbtxSeq, xstr(self.reuseIdentifier), xref(self.upstream).UTF8String, handled);
    if (handled) {
        [self.upstream sbtxCellDidTapWithIdentifier:self.reuseIdentifier];
    } else {
        printf("SBTX_CALLBACK skipped reuse=%s upstream=%s\n",
               xstr(self.reuseIdentifier), xref(self.upstream).UTF8String);
    }
}

@end

#pragma mark - controller

@implementation ExtPrototypeSceneController {
    NSInteger _tapCount;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        printf("SBTX_EXT initcoder seq=%d class=%s\n", ++gSbtxSeq, object_getClassName(self));
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    printf("SBTX_EXT awake seq=%d tableView=%s\n", ++gSbtxSeq, xref(self.tableView).UTF8String);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UITableView *table = self.tableView;
    printf("SBTX_VIEW didload seq=%d class=%s style=%ld rowHeight=%.3f dataSource=%s delegate=%s\n",
           ++gSbtxSeq, object_getClassName(table), (long)table.style, table.rowHeight,
           xref(table.dataSource).UTF8String, xref(table.delegate).UTF8String);
}

#pragma mark - data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    printf("SBTX_SRC rows section=%ld count=%ld\n", (long)section, 2L);
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        ExtOutletCell *cell = (ExtOutletCell *)[tableView dequeueReusableCellWithIdentifier:@"SBTXCell" forIndexPath:indexPath];
        cell.captionLabel.text = @"SBTX Row 1";
        // Subviews are read before textLabel/detailTextLabel, so a lazily created built-in
        // label can never change the archive profile printed here.
        NSString *subviews = xsubviews(cell.contentView);
        UILabel *builtinText = cell.textLabel;
        UILabel *builtinDetail = cell.detailTextLabel;
        printf("SBTX_ARCHIVE row=0 class=%s reuse=%s contentSubviews=%s textLabel=%s detailTextLabel=%s\n",
               object_getClassName(cell), xstr(cell.reuseIdentifier), subviews.UTF8String,
               xref(builtinText).UTF8String, xref(builtinDetail).UTF8String);
        printf("SBTX_SRC cell row=0 caption=%s upstream=%s\n",
               xstr(cell.captionLabel.text), xref(cell.upstream).UTF8String);
        return cell;
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SBTXSubtitleCell" forIndexPath:indexPath];
    NSString *subviews = xsubviews(cell.contentView);
    UILabel *builtinText = cell.textLabel;
    UILabel *builtinDetail = cell.detailTextLabel;
    printf("SBTX_ARCHIVE row=1 class=%s reuse=%s contentSubviews=%s textLabel=%s detailTextLabel=%s\n",
           object_getClassName(cell), xstr(cell.reuseIdentifier), subviews.UTF8String,
           xref(builtinText).UTF8String, xref(builtinDetail).UTF8String);
    return cell;
}

#pragma mark - callback of the external object

- (void)sbtxCellDidTapWithIdentifier:(NSString *)identifier {
    _tapCount += 1;
    UITableView *table = self.tableView;
    printf("SBTX_TAP identifier=%s count=%ld\n", xstr(identifier), (long)_tapCount);
    UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, table.bounds.size.width, 44.0)];
    status.text = @"SBTX_DONE";
    status.textAlignment = NSTextAlignmentCenter;
    [table setTableFooterView:status];
    [table layoutIfNeeded];
    printf("SBTX_DONE count=%ld footerText=%s footerFrame=%s\n", (long)_tapCount,
           xstr(status.text), xrect(status.frame).UTF8String);
}

#pragma mark - lifecycle

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    UITableView *table = self.tableView;
    [table layoutIfNeeded];
    printf("SBTX_LATE appear seq=%d rows=%ld content=%.3f,%.3f bounds=%s\n",
           ++gSbtxSeq, (long)[table numberOfRowsInSection:0], table.contentSize.width, table.contentSize.height,
           xrect(table.bounds).UTF8String);
    for (NSInteger row = 0; row < 2; row++) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
        UITableViewCell *cell = [table cellForRowAtIndexPath:path];
        if (!cell) {
            printf("SBTX_LATE row=%ld cell=nil\n", (long)row);
            continue;
        }
        UILabel *text = cell.textLabel;
        UILabel *detail = cell.detailTextLabel;
        printf("SBTX_BUILTIN row=%ld class=%s textLabel=%s text=%s color=%s font=%s frame=%s inContent=%d detailLabel=%s detail=%s detailColor=%s detailFont=%s detailFrame=%s detailInContent=%d\n",
               (long)row, object_getClassName(cell), xref(text).UTF8String, xstr(text.text).UTF8String,
               xrgba(text.textColor).UTF8String, xfont(text.font).UTF8String, xrect(text.frame).UTF8String,
               text != nil && text.superview == cell.contentView,
               xref(detail).UTF8String, xstr(detail.text).UTF8String,
               xrgba(detail.textColor).UTF8String, xfont(detail.font).UTF8String, xrect(detail.frame).UTF8String,
               detail != nil && detail.superview == cell.contentView);
    }
    printf("SBTX_READY rows=%ld\n", (long)[table numberOfRowsInSection:0]);
}

@end
