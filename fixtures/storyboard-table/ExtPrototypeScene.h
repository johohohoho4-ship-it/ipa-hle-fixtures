#import <UIKit/UIKit.h>

// Second, separate measurement section of the F5 storyboard reference (Sol request
// id f3f29743): a prototype cell whose custom class keeps outlets on objects that live
// OUTSIDE the cell nib. In Main.storyboard the cell wires `upstream`, `delegate` and
// `dataSource` to the scene's own controller, so ibtool has to archive those targets as
// external objects of the prototype nib - the construct that stops CleanStore with
// "prototype external objects are not measured: OrderTableViewCell bindet
// UpstreamPlaceholder-1".
//
// The section is only started by a launch argument from the XCUITest, so the original
// two-row SBT_ run stays untouched. All of its output is prefixed SBTX_ and follows the
// SBT_ section.

@protocol SBTXUpstream <NSObject>
- (void)sbtxCellDidTapWithIdentifier:(NSString *)identifier;
@end

@interface ExtPrototypeSceneController : UITableViewController <SBTXUpstream>
@end

@interface ExtOutletCell : UITableViewCell
// External target: provided by the scene controller, not by the cell nib.
@property (weak, nonatomic) IBOutlet id<SBTXUpstream> upstream;
@property (weak, nonatomic) IBOutlet id delegate;
@property (weak, nonatomic) IBOutlet id dataSource;
// Internal outlet of the same cell nib, measured for the connection order.
@property (weak, nonatomic) IBOutlet UILabel *captionLabel;
@end
