#import <UIKit/UIKit.h>

void TBPrint(NSString *format, ...);

@interface TabController : UIViewController
@property (nonatomic, copy) NSString *name;
@property (nonatomic, weak) UILabel *statusLabel;
@end
