#import <UIKit/UIKit.h>

@interface NavController : UIViewController
- (const char *)eventName;
@end

@interface RootController : NavController
@end

@interface LevelController : NavController
@property (nonatomic) int level;
@end
