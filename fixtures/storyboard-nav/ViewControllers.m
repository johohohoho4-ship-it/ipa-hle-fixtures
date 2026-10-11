#import "ViewControllers.h"
#include <stdio.h>

@implementation BadgeView
@end

@implementation CardOwner
@end

static void Log(const char *who, const char *what, UIViewController *vc) {
    printf("SB_EVENT %s %s nav=%d stack=%lu\n", who, what, vc.navigationController != nil,
           (unsigned long)vc.navigationController.viewControllers.count);
}

@implementation NavRootViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    Log("root", "viewDidLoad", self);
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    printf("SB_EVENT root didAppear animated=%d title=%s\n", animated, self.navigationItem.title.UTF8String);
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    printf("SB_EVENT root didDisappear animated=%d\n", animated);
}
- (IBAction)go:(id)sender {
    printf("SB_EVENT root go\n");
    [self performSegueWithIdentifier:@"toDetail" sender:sender];
}
- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    printf("SB_EVENT root should id=%s\n", identifier.UTF8String);
    return YES;
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    printf("SB_EVENT root prepare id=%s dest=%s source=%s nav=%d\n", segue.identifier.UTF8String,
           object_getClassName(segue.destinationViewController), object_getClassName(segue.sourceViewController),
           self.navigationController != nil);
    ((NavDetailViewController *)segue.destinationViewController).message = @"from root";
}
@end

@implementation NavDetailViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.detailLabel.text = [NSString stringWithFormat:@"Detail (%@)", self.message];
    Log("detail", "viewDidLoad", self);
    printf("SB_EVENT detail text=%s\n", self.detailLabel.text.UTF8String);
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    printf("SB_EVENT detail didAppear animated=%d stack=%lu\n", animated, (unsigned long)self.navigationController.viewControllers.count);
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    printf("SB_EVENT detail didDisappear animated=%d\n", animated);
}
- (IBAction)pop:(id)sender {
    printf("SB_EVENT detail pop\n");
    [self.navigationController popViewControllerAnimated:NO];
}
@end
