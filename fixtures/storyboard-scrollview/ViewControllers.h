#import <UIKit/UIKit.h>

// F5/F9 reference for a UIScrollView that comes from a storyboard nib: the scene is a
// plain UIViewController whose view contains the scroll view, the content container and
// two controls. The scroll view's delegate outlet points at the controller. Everything
// the F5/F9 decoder must reproduce (coder state, awake order, hierarchy, content size,
// real drag and nonanimated offset/inset changes) is printed as SCN_* lines.

@interface SCNScrollViewController : UIViewController <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIButton *stepButton;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@end
