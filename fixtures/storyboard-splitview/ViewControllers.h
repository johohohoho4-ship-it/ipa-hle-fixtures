#import <UIKit/UIKit.h>

// F5/B4 reference for a UISplitViewController that is decoded from Main.storyboard:
// the split scene is the initial controller, master and detail are its two relationship
// children. Measured are the archived/coder profile (display modes, edge, gesture,
// collapsed state, children), the controller identities and parent links, the callback
// order for portrait, landscape and back, and the geometry after layout. Every printed
// value is read from UIKit; nothing here asserts an expected value.

@interface SPVSplitViewController : UISplitViewController
@end

@interface SPVMasterViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
- (void)setStatusText:(NSString *)text;
@end

@interface SPVDetailViewController : UIViewController
@end
