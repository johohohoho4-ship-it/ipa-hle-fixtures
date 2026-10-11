#import "ViewController.h"
@import QuartzCore;
#include <stdio.h>
@interface ViewController ()
@property(nonatomic,strong) NSArray *squares;
@property(nonatomic,strong) UILabel *status;
@property(nonatomic) NSInteger stage;
@end
@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=UIColor.whiteColor;
    NSMutableArray *squares=[NSMutableArray array];
    NSArray *names=@[@"linear",@"default",@"easeIn",@"easeOut",@"easeInEaseOut",@"custom",@"nil"];
    for(NSInteger i=0;i<7;i++) {
        UIView *square=[[UIView alloc] initWithFrame:CGRectMake(25+(i%3)*115,105+(i/3)*95,80,70)];
        square.backgroundColor=UIColor.blueColor;
        [self.view addSubview:square];
        [squares addObject:square];
        CAMediaTimingFunction *curve=nil;
        if(i==5) curve=[[CAMediaTimingFunction alloc] initWithControlPoints:0.2f :0.4f :0.8f :0.6f];
        else if(i<5) curve=[CAMediaTimingFunction functionWithName:names[i]];
        if(curve) {
            for(NSInteger j=0;j<4;j++) {
                float point[2]={-9,-9};
                [curve getControlPointAtIndex:j values:point];
                printf("CURVE_POINT i=%ld j=%ld x=%.6f y=%.6f\n",(long)i,(long)j,point[0],point[1]);
            }
        }
        [CATransaction begin]; [CATransaction setDisableActions:YES];
        square.layer.opacity=0.8f; square.layer.speed=0; square.layer.timeOffset=0;
        [CATransaction commit];
        CABasicAnimation *fade=[CABasicAnimation animationWithKeyPath:@"opacity"];
        fade.fromValue=[NSNumber numberWithDouble:0.2]; fade.toValue=[NSNumber numberWithDouble:1];
        fade.duration=2; fade.removedOnCompletion=NO; fade.fillMode=@"forwards";
        fade.timingFunction=curve;
        [square.layer addAnimation:fade forKey:@"fade"];
        // Mutating the source must not alter the installed timing curve.
        fade.timingFunction=[CAMediaTimingFunction functionWithName:@"linear"];
    }
    self.squares=squares;
    self.status=[[UILabel alloc] initWithFrame:CGRectMake(25,400,330,40)];
    self.status.textColor=UIColor.blackColor; self.status.accessibilityIdentifier=@"curve.status";
    [self.view addSubview:self.status];
    SEL selectors[]={@selector(quarter:),@selector(half:),@selector(threequarters:),@selector(afterend:)};
    for(NSInteger i=0;i<4;i++) {
        UIButton *button=[UIButton buttonWithType:UIButtonTypeSystem];
        button.frame=CGRectMake(25,460+i*55,250,44);
        [button setTitle:[NSString stringWithFormat:@"Step %ld",(long)i+1] forState:UIControlStateNormal];
        button.accessibilityIdentifier=[NSString stringWithFormat:@"curve.step%ld",(long)i+1];
        [button addTarget:self action:selectors[i] forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    }
}
- (void)viewDidAppear:(BOOL)animated { [super viewDidAppear:animated]; [self schedule]; }
- (void)schedule { [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(sample:) userInfo:nil repeats:NO]; }
- (void)quarter:(id)sender { self.stage=1; [self step]; }
- (void)half:(id)sender { self.stage=2; [self step]; }
- (void)threequarters:(id)sender { self.stage=3; [self step]; }
- (void)afterend:(id)sender { self.stage=4; [self step]; }
- (void)step {
    double offsets[]={0,0.5,1,1.5,2.5};
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    for(UIView *square in self.squares) square.layer.timeOffset=offsets[self.stage];
    [CATransaction commit]; [CATransaction flush]; [self schedule];
}
- (void)sample:(NSTimer *)timer {
    for(NSInteger i=0;i<self.squares.count;i++) {
        UIView *square=self.squares[i];
        printf("CURVE_SAMPLE stage=%ld i=%ld model=%.6f presentation=%.6f\n",(long)self.stage,(long)i,square.layer.opacity,square.layer.presentationLayer.opacity);
    }
    self.status.text=[NSString stringWithFormat:@"Stage %ld",(long)self.stage];
}
@end
