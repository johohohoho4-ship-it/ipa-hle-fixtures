#import "Controllers.h"
#include <stdio.h>

// Two stores, one counter each: a text file in Documents and NSUserDefaults. Both must come back after a restart.

@interface CounterController ()
@property (nonatomic, strong) UILabel *label;
@end

@implementation CounterController

- (NSString *)path {
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [documents stringByAppendingPathComponent:@"counter.txt"];
}

- (NSInteger)fileCount {
    NSString *text = [NSString stringWithContentsOfFile:self.path encoding:NSUTF8StringEncoding error:nil];
    return text.integerValue;
}

- (void)show {
    self.label.text = [NSString stringWithFormat:@"file %ld defaults %ld", (long)[self fileCount],
                       (long)[NSUserDefaults.standardUserDefaults integerForKey:@"count"]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.label = [[UILabel alloc] initWithFrame:CGRectMake(20, 120, 350, 30)];
    self.label.accessibilityIdentifier = @"p.label";
    [self.view addSubview:self.label];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(20, 170, 200, 44);
    [button setTitle:@"Count" forState:UIControlStateNormal];
    button.accessibilityIdentifier = @"p.count";
    [button addTarget:self action:@selector(count) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    [self show];
    printf("PERSIST_EVENT start %s\n", self.label.text.UTF8String);
}

- (void)count {
    NSInteger next = [self fileCount] + 1;
    [[NSString stringWithFormat:@"%ld", (long)next] writeToFile:self.path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setInteger:[defaults integerForKey:@"count"] + 1 forKey:@"count"];
    [self show];
    printf("PERSIST_EVENT count %s\n", self.label.text.UTF8String);
}

@end
