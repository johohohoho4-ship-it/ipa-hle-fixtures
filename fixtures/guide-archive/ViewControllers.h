#import <UIKit/UIKit.h>

@interface GuideArchiveViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (copy, nonatomic) NSString *phaseOverride;
@property (nonatomic) BOOL didRun;
@end
