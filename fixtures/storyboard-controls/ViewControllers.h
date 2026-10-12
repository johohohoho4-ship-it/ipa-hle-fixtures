#import <UIKit/UIKit.h>

@interface SBControlsViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIStackView *stackView;
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UISwitch *toggle;
@property (weak, nonatomic) IBOutlet UIView *tapView;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;
- (IBAction)tapped:(UITapGestureRecognizer *)sender;
- (IBAction)toggled:(UISwitch *)sender;
@end
