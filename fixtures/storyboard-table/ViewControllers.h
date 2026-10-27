#import <UIKit/UIKit.h>

// F5 reference for a table view that comes from a storyboard nib: the scene is a
// UITableViewController whose tableView carries a prototype cell with a custom class and
// two outlets. Everything the F5 decoder must reproduce (coder defaults, prototype
// registration, outlet wiring, awake order) is printed as SBT_* lines.

@interface TableSceneController : UITableViewController
@end

@interface TableCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@end
