#import "ViewController.h"
#include <stdio.h>

@interface TouchSurface : UIView
@property(nonatomic, strong) UITouch *first;
- (void)report:(NSString *)phase touches:(NSSet<UITouch *> *)touches event:(UIEvent *)event;
@end
@implementation TouchSurface
- (void)report:(NSString *)phase touches:(NSSet<UITouch *> *)touches event:(UIEvent *)event {
    UITouch *touch = touches.anyObject;
    if (touch.phase == UITouchPhaseBegan) self.first = touch;
    CGPoint local = [touch locationInView:self];
    CGPoint previous = [touch previousLocationInView:self];
    CGPoint window = [touch locationInView:nil];
    printf("TCH_VIEW phase=%s state=%ld count=%lu same=%d view=%d window=%d local=%.1f,%.1f previous=%.1f,%.1f point=%.1f,%.1f all=%lu own=%lu time=%.6f\n",
        phase.UTF8String, (long)touch.phase, (unsigned long)touches.count, touch == self.first, touch.view == self,
        touch.window != nil, local.x, local.y, previous.x, previous.y, window.x, window.y,
        (unsigned long)event.allTouches.count, (unsigned long)[event touchesForView:self].count, touch.timestamp);
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self report:@"began" touches:touches event:event]; [super touchesBegan:touches withEvent:event];
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self report:@"moved" touches:touches event:event]; [super touchesMoved:touches withEvent:event];
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self report:@"ended" touches:touches event:event]; [super touchesEnded:touches withEvent:event];
}
@end

@interface ViewController ()
@property(nonatomic, strong) UILabel *status;
@property(nonatomic) NSInteger completed;
@end
@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad]; self.view.backgroundColor = UIColor.whiteColor;
    TouchSurface *surface = [[TouchSurface alloc] initWithFrame:CGRectMake(40, 110, 220, 240)];
    surface.backgroundColor = UIColor.blueColor; surface.accessibilityIdentifier = @"touch.surface";
    [self.view addSubview:surface];
    self.status = [[UILabel alloc] initWithFrame:CGRectMake(30, 550, 330, 45)];
    self.status.text = @"Ready"; self.status.accessibilityIdentifier = @"touch.status";
    [self.view addSubview:self.status];
    printf("TCH_CONFIG next=%d rootnext=%d\n", surface.nextResponder == self.view, self.view.nextResponder == self);
}
- (void)report:(NSString *)phase touches:(NSSet<UITouch *> *)touches event:(UIEvent *)event {
    UITouch *touch = touches.anyObject;
    printf("TCH_CONTROLLER phase=%s state=%ld count=%lu root=%lu all=%lu type=%ld\n", phase.UTF8String,
        (long)touch.phase, (unsigned long)touches.count, (unsigned long)[event touchesForView:self.view].count,
        (unsigned long)event.allTouches.count, (long)event.type);
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self report:@"began" touches:touches event:event];
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self report:@"moved" touches:touches event:event];
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self report:@"ended" touches:touches event:event];
    self.completed++; self.status.text = [NSString stringWithFormat:@"Done %ld", (long)self.completed];
}
@end
