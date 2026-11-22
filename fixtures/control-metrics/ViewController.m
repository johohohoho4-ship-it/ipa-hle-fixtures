#import "ViewController.h"
#include <stdio.h>

// F3/F5: measured control geometry. The native console reports the intrinsic
// content size, alignmentRectInsets and alignmentRectForFrame: of a UITextField
// (RoundedRect, 14 pt) and a UISwitch, and the AutoLayout result when those
// controls are paired with each other and with plain UIViews at centerY
// constraints with integer, half, third and sixth point offsets. Nothing here
// asserts expected values; every number is read from the runtime.

static void printSize(const char *kind, const char *name, CGSize size) {
    printf("CM_INTRINSIC kind=%s name=%s w=%.4f h=%.4f\n",
           kind, name, size.width, size.height);
    fflush(stdout);
}

static void printInsets(const char *name, UIEdgeInsets insets) {
    printf("CM_INSETS name=%s top=%.4f left=%.4f bottom=%.4f right=%.4f\n",
           name, insets.top, insets.left, insets.bottom, insets.right);
    fflush(stdout);
}

static void printAlignment(const char *name, const char *which, CGRect rect) {
    printf("CM_ALIGN name=%s rect=%s x=%.4f y=%.4f w=%.4f h=%.4f cx=%.4f cy=%.4f\n",
           name, which, rect.origin.x, rect.origin.y, rect.size.width,
           rect.size.height, CGRectGetMidX(rect), CGRectGetMidY(rect));
    fflush(stdout);
}

static UIView *makeBox(CGFloat height) {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = UIColor.systemGrayColor;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [view.heightAnchor constraintEqualToConstant:height].active = YES;
    return view;
}

static UITextField *makeField(void) {
    UITextField *field = [[UITextField alloc] initWithFrame:CGRectZero];
    field.borderStyle = UITextBorderStyleRoundedRect;
    field.font = [UIFont systemFontOfSize:14.0];
    field.text = @"Ada";
    field.placeholder = @"Name";
    field.translatesAutoresizingMaskIntoConstraints = NO;
    return field;
}

static UISwitch *makeSwitch(void) {
    UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
    toggle.on = YES;
    toggle.translatesAutoresizingMaskIntoConstraints = NO;
    return toggle;
}

@interface ViewController ()
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *rows;
@property (nonatomic, strong) UITextField *intrinsicField;
@property (nonatomic, strong) UISwitch *intrinsicSwitch;
@property (nonatomic) BOOL printed;
@end

@implementation ViewController

- (void)addRowNamed:(NSString *)name
           leftView:(UIView *)left
          rightView:(UIView *)right
        leftWidth:(CGFloat)leftWidth
       rightWidth:(CGFloat)rightWidth
             offset:(CGFloat)offset
                  y:(CGFloat)y {
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(20, y, 353, 44)];
    container.backgroundColor = UIColor.secondarySystemBackgroundColor;
    [self.view addSubview:container];

    left.translatesAutoresizingMaskIntoConstraints = NO;
    right.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:left];
    [container addSubview:right];

    [left.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:8].active = YES;
    [left.centerYAnchor constraintEqualToAnchor:container.centerYAnchor].active = YES;
    [left.widthAnchor constraintEqualToConstant:leftWidth].active = YES;

    [right.leadingAnchor constraintEqualToAnchor:left.trailingAnchor constant:8].active = YES;
    [right.centerYAnchor constraintEqualToAnchor:left.centerYAnchor constant:offset].active = YES;
    [right.widthAnchor constraintEqualToConstant:rightWidth].active = YES;

    [self.rows addObject:@{@"name": name, @"left": left, @"right": right,
                           @"offset": @(offset)}];
}

- (void)printRow:(NSDictionary *)row {
    UIView *left = row[@"left"];
    UIView *right = row[@"right"];
    CGRect lf = left.frame;
    CGRect rf = right.frame;
    CGSize li = left.intrinsicContentSize;
    CGSize ri = right.intrinsicContentSize;
    UIEdgeInsets lins = left.alignmentRectInsets;
    UIEdgeInsets rins = right.alignmentRectInsets;
    double offset = [row[@"offset"] doubleValue];
    printf("CM_ROW name=%s left=%s right=%s offset=%.4f "
           "leftFrame=(%.4f,%.4f,%.4f,%.4f) leftCenterY=%.4f leftIntrinsic=(%.4f,%.4f) "
           "leftInsets=(%.4f,%.4f,%.4f,%.4f) "
           "rightFrame=(%.4f,%.4f,%.4f,%.4f) rightCenterY=%.4f rightIntrinsic=(%.4f,%.4f) "
           "rightInsets=(%.4f,%.4f,%.4f,%.4f) dy=%.4f dyAlign=%.4f\n",
           [row[@"name"] UTF8String],
           NSStringFromClass(left.class).UTF8String,
           NSStringFromClass(right.class).UTF8String, offset,
           lf.origin.x, lf.origin.y, lf.size.width, lf.size.height,
           CGRectGetMidY(lf), li.width, li.height,
           lins.top, lins.left, lins.bottom, lins.right,
           rf.origin.x, rf.origin.y, rf.size.width, rf.size.height,
           CGRectGetMidY(rf), ri.width, ri.height,
           rins.top, rins.left, rins.bottom, rins.right,
           CGRectGetMidY(rf) - CGRectGetMidY(lf),
           CGRectGetMidY([right alignmentRectForFrame:rf]) -
               CGRectGetMidY([left alignmentRectForFrame:lf]));
    fflush(stdout);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.rows = [NSMutableArray array];

    UIScreen *screen = UIScreen.mainScreen;
    CGRect bounds = screen.bounds;
    printf("CM_SCREEN scale=%.4f nativeScale=%.4f bounds=(%.4f,%.4f,%.4f,%.4f)\n",
           screen.scale, screen.nativeScale,
           bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
    fflush(stdout);

    // Intrinsic and alignment data of both controls, independent of the rows.
    self.intrinsicField = makeField();
    self.intrinsicSwitch = makeSwitch();
    printSize("field", "rounded-14", self.intrinsicField.intrinsicContentSize);
    printInsets("UITextField", self.intrinsicField.alignmentRectInsets);
    printSize("switch", "default", self.intrinsicSwitch.intrinsicContentSize);
    printInsets("UISwitch", self.intrinsicSwitch.alignmentRectInsets);

    CGFloat y = 100;
    CGFloat step = 70;

    [self addRowNamed:@"view34-view31" leftView:makeBox(34) rightView:makeBox(31)
            leftWidth:120 rightWidth:60 offset:0 y:y];
    y += step;
    [self addRowNamed:@"field-switch-0" leftView:makeField() rightView:makeSwitch()
            leftWidth:200 rightWidth:51 offset:0 y:y];
    y += step;
    [self addRowNamed:@"field-switch-half" leftView:makeField() rightView:makeSwitch()
            leftWidth:200 rightWidth:51 offset:0.5 y:y];
    y += step;
    [self addRowNamed:@"field-switch-third" leftView:makeField() rightView:makeSwitch()
            leftWidth:200 rightWidth:51 offset:(1.0 / 3.0) y:y];
    y += step;
    [self addRowNamed:@"field-switch-sixth" leftView:makeField() rightView:makeSwitch()
            leftWidth:200 rightWidth:51 offset:(1.0 / 6.0) y:y];
    y += step;
    [self addRowNamed:@"view34-switch-0" leftView:makeBox(34) rightView:makeSwitch()
            leftWidth:120 rightWidth:51 offset:0 y:y];
    y += step;
    [self addRowNamed:@"field-view31-0" leftView:makeField() rightView:makeBox(31)
            leftWidth:200 rightWidth:60 offset:0 y:y];
    y += step;
    [self addRowNamed:@"view36-switch-0" leftView:makeBox(36) rightView:makeSwitch()
            leftWidth:120 rightWidth:51 offset:0 y:y];

    UILabel *status = [[UILabel alloc] initWithFrame:CGRectZero];
    status.accessibilityIdentifier = @"cm.status";
    status.text = @"CM_PENDING";
    status.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:status];
    [status.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20].active = YES;
    [status.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-40].active = YES;

    [self.view layoutIfNeeded];

    // Alignment rectangles for the intrinsic and the resolved frames of both
    // controls. The intrinsic rect is placed at the origin; only its size and
    // the derived alignment rect matter here.
    CGRect fieldIntrinsic = (CGRect){CGPointZero, self.intrinsicField.intrinsicContentSize};
    printAlignment("UITextField", "intrinsic", [self.intrinsicField alignmentRectForFrame:fieldIntrinsic]);
    CGRect switchIntrinsic = (CGRect){CGPointZero, self.intrinsicSwitch.intrinsicContentSize};
    printAlignment("UISwitch", "intrinsic", [self.intrinsicSwitch alignmentRectForFrame:switchIntrinsic]);

    for (NSDictionary *row in self.rows) {
        [self printRow:row];
    }

    // The first text field and switch of the row list are inside the layout now;
    // their resolved frames feed alignmentRectForFrame: again.
    NSDictionary *fieldRow = self.rows[1];
    UIView *laidField = fieldRow[@"left"];
    UIView *laidSwitch = fieldRow[@"right"];
    printAlignment("UITextField", "resolved", [laidField alignmentRectForFrame:laidField.frame]);
    printAlignment("UISwitch", "resolved", [laidSwitch alignmentRectForFrame:laidSwitch.frame]);

    printf("CM_DONE rows=%lu\n", (unsigned long)self.rows.count);
    fflush(stdout);
    status.text = @"CM_DONE";
}

@end
