#import "ViewController.h"
#include <stdio.h>

// F3/F5: measured control geometry. The native console reports the intrinsic
// content size, alignmentRectInsets and alignmentRectForFrame: of a UITextField
// (RoundedRect, 14 pt) and a UISwitch, and the AutoLayout result when those
// controls are paired with each other and with plain UIViews at centerY
// constraints with integer, half, third and sixth point offsets. It also
// reports fractional and negative edge coordinates that separate edge rounding
// from origin-plus-size rounding. Nothing here asserts expected values; every
// number is read from the runtime.

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

// F3: intrinsic width profiles of the rounded text field. The font stays
// Regular system; only point size, text and placeholder vary. Every value is
// read from the runtime.
static UITextField *makeProfileField(CGFloat pointSize, NSString *text, NSString *placeholder) {
    UITextField *field = [[UITextField alloc] initWithFrame:CGRectZero];
    field.borderStyle = UITextBorderStyleRoundedRect;
    field.font = [UIFont systemFontOfSize:pointSize];
    field.text = text;
    field.placeholder = placeholder;
    return field;
}

@interface ViewController ()
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *rows;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *rasterRows;
@property (nonatomic, strong) UIView *rasterContainer;
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

// Raster separation cases. Each view is placed by required Auto Layout
// constraints; the printed frame is the runtime result. The container sits at
// the screen origin, so frame coordinates are also absolute coordinates.
- (void)addRasterRowNamed:(NSString *)name
                        x:(CGFloat)x
                        y:(CGFloat)y
                    width:(CGFloat)width
                   height:(CGFloat)height {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = UIColor.systemBlueColor;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.rasterContainer addSubview:view];

    [view.leadingAnchor constraintEqualToAnchor:self.rasterContainer.leadingAnchor constant:x].active = YES;
    [view.topAnchor constraintEqualToAnchor:self.rasterContainer.topAnchor constant:y].active = YES;
    [view.widthAnchor constraintEqualToConstant:width].active = YES;
    [view.heightAnchor constraintEqualToConstant:height].active = YES;

    [self.rasterRows addObject:@{@"name": name, @"view": view}];
}

- (void)printRasterRow:(NSDictionary *)row {
    CGRect frame = ((UIView *)row[@"view"]).frame;
    printf("CM_RASTER name=%s frame=(%.4f,%.4f,%.4f,%.4f) "
           "center=(%.4f,%.4f)\n",
           [row[@"name"] UTF8String],
           frame.origin.x, frame.origin.y, frame.size.width, frame.size.height,
           CGRectGetMidX(frame), CGRectGetMidY(frame));
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

    // Width profiles: empty text, short text, a long sentence and a placeholder
    // each at 14 and 17 pt Regular. The intrinsic size is printed before Auto
    // Layout resolves any width constraint.
    NSArray<NSNumber *> *pointSizes = @[@14.0, @17.0];
    NSArray<NSArray *> *profiles = @[
        @[@"empty", [NSNull null], [NSNull null]],
        @[@"ada", @"Ada", [NSNull null]],
        @[@"long", @"The quick brown fox jumps over the lazy dog", [NSNull null]],
        @[@"placeholder", [NSNull null], @"Name"],
    ];
    for (NSNumber *pointSize in pointSizes) {
        for (NSArray *profile in profiles) {
            id textValue = profile[1];
            id placeholderValue = profile[2];
            NSString *text = [textValue isKindOfClass:[NSNull class]] ? nil : textValue;
            NSString *placeholder = [placeholderValue isKindOfClass:[NSNull class]] ? nil : placeholderValue;
            UITextField *field = makeProfileField(pointSize.doubleValue, text, placeholder);
            CGSize size = field.intrinsicContentSize;
            UIEdgeInsets insets = field.alignmentRectInsets;
            UIFont *font = field.font;
            printf("CM_FIELD size=%.4f profile=%s text=%s placeholder=%s "
                   "intrinsic=(%.4f,%.4f) insets=(%.4f,%.4f,%.4f,%.4f) "
                   "font=%s family=%s point=%.4f\n",
                   pointSize.doubleValue,
                   [profile[0] UTF8String],
                   text == nil ? "none" : [text UTF8String],
                   placeholder == nil ? "none" : [placeholder UTF8String],
                   size.width, size.height,
                   insets.top, insets.left, insets.bottom, insets.right,
                   font.fontName.UTF8String, font.familyName.UTF8String, font.pointSize);
            fflush(stdout);
        }
    }

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

    // Separation cases for the 1/scale edge grid. The container sits at (0,0),
    // so a negative x or y is also negative in window coordinates.
    self.rasterContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 393, 200)];
    self.rasterContainer.backgroundColor = UIColor.clearColor;
    [self.view addSubview:self.rasterContainer];
    self.rasterRows = [NSMutableArray array];
    [self addRasterRowNamed:@"edge-x8.2-w0.2" x:8.2 y:0 width:0.2 height:10];
    [self addRasterRowNamed:@"edge-x8.25-w10.25" x:8.25 y:20 width:10.25 height:10];
    [self addRasterRowNamed:@"half-x8.5-w10" x:8.5 y:40 width:10 height:10];
    [self addRasterRowNamed:@"negative-x-half" x:-6.5 y:60 width:20 height:10];
    [self addRasterRowNamed:@"negative-x-quarter" x:-6.25 y:80 width:20 height:10];
    [self addRasterRowNamed:@"negative-y-half" x:20 y:-6.5 width:20 height:10];

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

    for (NSDictionary *row in self.rasterRows) {
        [self printRasterRow:row];
    }
    printf("CM_RASTER_DONE rows=%lu\n", (unsigned long)self.rasterRows.count);

    printf("CM_DONE rows=%lu\n", (unsigned long)self.rows.count);
    fflush(stdout);
    status.text = @"CM_DONE";
}

@end
