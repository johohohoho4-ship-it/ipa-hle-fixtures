#import "ViewControllers.h"
#include <stdio.h>

// F5 reference: the classes a real ibtool storyboard stores beyond UIView/UILabel/UIButton/UIImageView: a stack view
// with arranged labels, a text field, a switch, a tap gesture recognizer, an outlet collection and a control action.
// Every line starts with SBCTL; the HLE replays the same compiled storyboard and must print the same lines.

static NSString *Frame(CGRect r) { return [NSString stringWithFormat:@"%g,%g,%g,%g", r.origin.x, r.origin.y, r.size.width, r.size.height]; }

@implementation SBControlsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    printf("SBCTL load outlets stack=%d field=%d toggle=%d tap=%d labels=%lu\n", self.stackView != nil, self.nameField != nil,
           self.toggle != nil, self.tapView != nil, (unsigned long)self.labels.count);
    printf("SBCTL stack axis=%ld spacing=%g distribution=%ld alignment=%ld arranged=%lu subviews=%lu\n", (long)self.stackView.axis,
           self.stackView.spacing, (long)self.stackView.distribution, (long)self.stackView.alignment,
           (unsigned long)self.stackView.arrangedSubviews.count, (unsigned long)self.stackView.subviews.count);
    for (UILabel *label in self.labels)
        printf("SBCTL collection label text=%s tag=%ld inStack=%d\n", label.text.UTF8String, (long)label.tag,
               [self.stackView.arrangedSubviews containsObject:label]);
    printf("SBCTL field text=%s placeholder=%s border=%ld font=%g\n", self.nameField.text ? self.nameField.text.UTF8String : "(nil)",
           self.nameField.placeholder.UTF8String, (long)self.nameField.borderStyle, self.nameField.font.pointSize);
    printf("SBCTL switch on=%d\n", self.toggle.on);
    UIGestureRecognizer *gesture = self.tapView.gestureRecognizers.firstObject;
    printf("SBCTL gesture count=%lu class=%s taps=%ld touches=%ld\n", (unsigned long)self.tapView.gestureRecognizers.count,
           gesture ? NSStringFromClass([gesture class]).UTF8String : "(none)",
           (long)([gesture isKindOfClass:[UITapGestureRecognizer class]] ? ((UITapGestureRecognizer *)gesture).numberOfTapsRequired : -1),
           (long)([gesture isKindOfClass:[UITapGestureRecognizer class]] ? ((UITapGestureRecognizer *)gesture).numberOfTouchesRequired : -1));
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    printf("SBCTL frame stack=%s field=%s toggle=%s tap=%s\n", Frame(self.stackView.frame).UTF8String,
           Frame(self.nameField.frame).UTF8String, Frame(self.toggle.frame).UTF8String, Frame(self.tapView.frame).UTF8String);
    for (UILabel *label in self.labels) printf("SBCTL label %s frame=%s\n", label.text.UTF8String, Frame(label.frame).UTF8String);
}

- (void)tapped:(UITapGestureRecognizer *)sender {
    printf("SBCTL tapped state=%ld\n", (long)sender.state);
}

- (void)toggled:(UISwitch *)sender {
    printf("SBCTL toggled on=%d\n", sender.on);
}

@end
