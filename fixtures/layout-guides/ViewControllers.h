#import <UIKit/UIKit.h>

@interface BadgeView : UIView
@end

@interface CardOwner : NSObject
@property (weak, nonatomic) IBOutlet UILabel *captionLabel;
@end

@interface NavRootViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *rootLabel;
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightItem;
- (IBAction)go:(id)sender;
- (IBAction)plain:(id)sender;
- (IBAction)addTapped:(id)sender;
- (IBAction)rightTapped:(id)sender;
@end

@interface NavDetailViewController : UIViewController
@property (copy, nonatomic) NSString *message;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
- (IBAction)pop:(id)sender;
@end

@interface PlainViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *plainLabel;
- (IBAction)close:(id)sender;
@end
