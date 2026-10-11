#import <UIKit/UIKit.h>

@interface BadgeView : UIView
@end

@interface CardOwner : NSObject
@property (weak, nonatomic) IBOutlet UILabel *captionLabel;
@end

@interface FirstViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet BadgeView *badge;
- (IBAction)tapped:(id)sender;
- (IBAction)go:(id)sender;
@end

@interface SecondViewController : UIViewController
@property (copy, nonatomic) NSString *message;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
- (IBAction)close:(id)sender;
@end
