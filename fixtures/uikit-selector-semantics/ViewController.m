#import "ViewController.h"
#include <stdio.h>

// P3 measurement fixture for the ObjC selector clarification (Sol's review of 5603d064).
// It reads two UIKit behaviours whose exact result was not measured yet:
//
//   -[UIView viewWithTag:]   which view wins when several match, in particular a deep
//                            match against a shallow one and two matching siblings.
//   -[UIButton imageForState:] what the getter returns for a control state that was
//                            never set (nil against the control's normal image).
//
// Nothing here asserts an expected value; every line is what the simulator returned.

static const char *flag(BOOL value) { return value ? "1" : "0"; }

static void printTag(const char *name, NSInteger tag, UIView *result,
                     UIView *first, UIView *second) {
    printf("SELM_TAG case=%s tag=%ld found=%s same_first=%s same_second=%s\n",
           name, (long)tag, flag(result != nil),
           first ? flag(result == first) : "-",
           second ? flag(result == second) : "-");
    fflush(stdout);
}

static void printButtonImage(const char *name, unsigned long state, UIImage *result,
                             UIImage *normal, UIImage *highlighted) {
    printf("SELM_BTN case=%s state=%lu same_normal=%s same_highlighted=%s nil=%s\n",
           name, state, flag(result == normal), flag(result == highlighted),
           flag(result == nil));
    fflush(stdout);
}

@interface ViewController ()
@property(nonatomic, strong) UILabel *status;
@property(nonatomic) BOOL measured;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(20, 380, 350, 45);
    [button setTitle:@"Run" forState:UIControlStateNormal];
    button.accessibilityIdentifier = @"selm.run";
    [button addTarget:self action:@selector(runMeasurements:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];

    self.status = [[UILabel alloc] initWithFrame:CGRectMake(20, 440, 350, 45)];
    self.status.text = @"Ready";
    self.status.accessibilityIdentifier = @"selm.status";
    [self.view addSubview:self.status];
}

- (void)runMeasurements:(UIButton *)sender {
    if (self.measured) return;                       // one block per launch keeps the log stable
    self.measured = YES;
    printf("SELM_START\n");
    fflush(stdout);
    [self measureViewWithTag];
    [self measureButtonImages];
    printf("SELM_END\n");
    fflush(stdout);
    self.status.text = @"DONE";
}

#pragma mark - 1. viewWithTag: with duplicate tags

- (void)measureViewWithTag {
    UIView *root = [[UIView alloc] initWithFrame:CGRectMake(20, 60, 200, 100)];
    root.tag = 42;
    [self.view addSubview:root];

    // Children in this order: a, b, d, e, f. c is a child of a, so the only matching
    // tag 5 views are b (depth 1) and c (depth 2). A breadth-first search must find b,
    // a depth-first search that descends into a first must find c.
    UIView *a = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    a.tag = 11;
    [root addSubview:a];

    UIView *b = [[UIView alloc] initWithFrame:CGRectMake(50, 0, 50, 50)];
    b.tag = 5;
    [root addSubview:b];

    UIView *d = [[UIView alloc] initWithFrame:CGRectMake(0, 50, 50, 50)];
    d.tag = 6;
    [root addSubview:d];

    UIView *e = [[UIView alloc] initWithFrame:CGRectMake(50, 50, 50, 50)];
    e.tag = 6;
    [root addSubview:e];

    // root itself is 42; this child repeats it, so the receiver must win.
    UIView *f = [[UIView alloc] initWithFrame:CGRectMake(100, 0, 50, 50)];
    f.tag = 42;
    [root addSubview:f];

    UIView *c = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    c.tag = 5;
    [a addSubview:c];

    // Two siblings with tag 6: the earlier subview (d) and the later one (e).
    printTag("siblings", 6, [root viewWithTag:6], d, e);
    // Depth-2 child c against depth-1 sibling b.
    printTag("depth-vs-breadth", 5, [root viewWithTag:5], c, b);
    // The receiver and one of its children both carry 42.
    printTag("receiver-and-child", 42, [root viewWithTag:42], root, f);
    // Single match below the receiver.
    printTag("child-only", 11, [root viewWithTag:11], a, nil);
    // No match at all.
    printTag("missing", 99, [root viewWithTag:99], nil, nil);
}

#pragma mark - 2. imageForState: for states that were never set

- (void)measureButtonImages {
    UIImage *normal = [[UIImage alloc] init];
    UIImage *highlighted = [[UIImage alloc] init];

    UIButton *normalOnly = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    [normalOnly setImage:normal forState:UIControlStateNormal];
    const unsigned long allStates[] = {
        UIControlStateNormal,
        UIControlStateHighlighted,
        UIControlStateDisabled,
        UIControlStateSelected,
        UIControlStateFocused,
        UIControlStateApplication,
        UIControlStateReserved,
    };
    for (size_t i = 0; i < sizeof(allStates) / sizeof(allStates[0]); i++) {
        UIImage *result = [normalOnly imageForState:(UIControlState)allStates[i]];
        printButtonImage("normal-only", allStates[i], result, normal, highlighted);
    }

    UIButton *normalAndHighlighted = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    [normalAndHighlighted setImage:normal forState:UIControlStateNormal];
    [normalAndHighlighted setImage:highlighted forState:UIControlStateHighlighted];
    const unsigned long bothStates[] = {
        UIControlStateNormal, UIControlStateHighlighted,
        UIControlStateDisabled, UIControlStateSelected,
    };
    for (size_t i = 0; i < sizeof(bothStates) / sizeof(bothStates[0]); i++) {
        UIImage *result = [normalAndHighlighted imageForState:(UIControlState)bothStates[i]];
        printButtonImage("normal-and-highlighted", bothStates[i], result, normal, highlighted);
    }

    UIButton *empty = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    UIImage *emptyNormal = [empty imageForState:UIControlStateNormal];
    printButtonImage("no-images", UIControlStateNormal, emptyNormal, normal, highlighted);

    UIButton *cleared = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    [cleared setImage:normal forState:UIControlStateNormal];
    [cleared setImage:highlighted forState:UIControlStateHighlighted];
    [cleared setImage:nil forState:UIControlStateHighlighted];
    UIImage *clearedHighlighted = [cleared imageForState:UIControlStateHighlighted];
    printButtonImage("cleared-highlighted", UIControlStateHighlighted,
                     clearedHighlighted, normal, highlighted);
}

@end
