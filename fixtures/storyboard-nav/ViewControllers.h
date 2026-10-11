#import <UIKit/UIKit.h>

@interface BadgeView : UIView
@end

@interface CardOwner : NSObject
@property (weak, nonatomic) IBOutlet UILabel *captionLabel;
@end

@interface NavRootViewController : UIViewController
- (IBAction)go:(id)sender;
@end

@interface NavDetailViewController : UIViewController
@property (copy, nonatomic) NSString *message;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
- (IBAction)pop:(id)sender;
@end
