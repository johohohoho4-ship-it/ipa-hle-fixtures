#import "ViewControllers.h"
#include <stdio.h>

@implementation BadgeView
- (void)awakeFromNib {
    [super awakeFromNib];
    self.layer.cornerRadius = 6;
    printf("SB_EVENT badge awakeFromNib w=%.0f h=%.0f\n", self.frame.size.width, self.frame.size.height);
}
@end

@implementation CardOwner
@end

@implementation FirstViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    printf("SB_EVENT first viewDidLoad title=%s badge=%d\n", self.titleLabel.text.UTF8String, self.badge != nil);
    CardOwner *owner = [[CardOwner alloc] init];
    NSArray *objects = [[UINib nibWithNibName:@"Card" bundle:nil] instantiateWithOwner:owner options:nil];
    UIView *card = objects.firstObject;
    card.frame = CGRectMake(20, 360, 200, 50);
    [self.view addSubview:card];
    printf("SB_EVENT card objects=%lu caption=%s\n", (unsigned long)objects.count, owner.captionLabel.text.UTF8String);
    UIViewController *second = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"second"];
    printf("SB_EVENT instantiate second=%s\n", object_getClassName(second));
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    printf("SB_EVENT first didAppear\n");
}
- (IBAction)tapped:(id)sender {
    self.titleLabel.text = @"Tapped";
    printf("SB_EVENT first tapped\n");
}
- (IBAction)go:(id)sender {
    printf("SB_EVENT first go\n");
    [self performSegueWithIdentifier:@"toSecond" sender:sender];
}
- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    printf("SB_EVENT should id=%s\n", identifier.UTF8String);
    return YES;
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    printf("SB_EVENT prepare id=%s dest=%s\n", segue.identifier.UTF8String, object_getClassName(segue.destinationViewController));
    ((SecondViewController *)segue.destinationViewController).message = @"from first";
}
@end

@implementation SecondViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.messageLabel.text = [NSString stringWithFormat:@"Second scene (%@)", self.message];
    printf("SB_EVENT second viewDidLoad text=%s\n", self.messageLabel.text.UTF8String);
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    printf("SB_EVENT second didAppear\n");
}
- (IBAction)close:(id)sender {
    printf("SB_EVENT second close\n");
    [self dismissViewControllerAnimated:NO completion:nil];
}
@end
