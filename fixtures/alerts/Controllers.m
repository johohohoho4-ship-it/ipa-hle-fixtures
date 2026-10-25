#import "Controllers.h"
#include <stdarg.h>
#include <stdio.h>

void ALPrint(NSString *format, ...) {
    va_list arguments;
    va_start(arguments, format);
    NSString *line = [[NSString alloc] initWithFormat:format arguments:arguments];
    va_end(arguments);
    printf("%s\n", line.UTF8String);
    fflush(stdout);
}

@interface AlertsController ()
@property (nonatomic, strong) UILabel *status;
@property (nonatomic, strong) UIButton *menuButton;
@property (nonatomic) BOOL started;
@end

@implementation AlertsController

- (UIButton *)button:(NSString *)title identifier:(NSString *)identifier action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:title forState:UIControlStateNormal];
    button.accessibilityIdentifier = identifier;
    if (action) {
        [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    }
    [self.view addSubview:button];
    [NSLayoutConstraint activateConstraints:@[
        [button.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:20],
        [button.widthAnchor constraintEqualToConstant:220],
        [button.heightAnchor constraintEqualToConstant:44],
    ]];
    return button;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    self.status = [[UILabel alloc] init];
    self.status.accessibilityIdentifier = @"alerts.status";
    self.status.numberOfLines = 0;
    self.status.text = @"AL_READY";
    self.status.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.status];

    UIButton *alert = [self button:@"Show Alert" identifier:@"alerts.alert" action:@selector(showAlert)];
    UIButton *sheet = [self button:@"Show Sheet" identifier:@"alerts.sheet" action:@selector(showSheet)];
    self.menuButton = [self button:@"Show Menu" identifier:@"alerts.menu" action:NULL];

    UIAction *alpha = [UIAction actionWithTitle:@"Alpha" image:nil identifier:nil
                                        handler:^(UIAction *action) { [self result:@"MENU_ALPHA"]; }];
    UIAction *beta = [UIAction actionWithTitle:@"Beta" image:nil identifier:nil
                                       handler:^(UIAction *action) { [self result:@"MENU_BETA"]; }];
    self.menuButton.menu = [UIMenu menuWithTitle:@"Menu" children:@[alpha, beta]];
    self.menuButton.showsMenuAsPrimaryAction = YES;

    [NSLayoutConstraint activateConstraints:@[
        [self.status.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:20],
        [self.status.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
        [self.status.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-20],
        [alert.topAnchor constraintEqualToAnchor:self.status.bottomAnchor constant:20],
        [sheet.topAnchor constraintEqualToAnchor:alert.bottomAnchor constant:10],
        [self.menuButton.topAnchor constraintEqualToAnchor:sheet.bottomAnchor constant:10],
    ]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.started) {
        return;
    }
    self.started = YES;
    ALPrint(@"AL_START controller=%@", NSStringFromClass(self.class));
    NSMutableArray<NSString *> *children = [NSMutableArray array];
    for (UIMenuElement *element in self.menuButton.menu.children) {
        [children addObject:element.title ?: @"none"];
    }
    ALPrint(@"AL_MENU title=%@ children=%@", self.menuButton.menu.title,
            [children componentsJoinedByString:@","]);
    ALPrint(@"AL_DONE");
}

- (void)result:(NSString *)text {
    self.status.text = text;
    ALPrint(@"AL_ACTION=%@", text);
}

- (void)showAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert"
                                                                   message:@"Message"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) { [self result:@"ALERT_OK"]; }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) { [self result:@"ALERT_DELETE"]; }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) { [self result:@"ALERT_CANCEL"]; }]];
    ALPrint(@"AL_ALERT title=%@ message=%@ actions=OK,Delete,Cancel style=alert",
            alert.title, alert.message);
    [self presentViewController:alert animated:NO completion:nil];
}

- (void)showSheet {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Sheet"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:@"One" style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) { [self result:@"SHEET_ONE"]; }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Two" style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) { [self result:@"SHEET_TWO"]; }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) { [self result:@"SHEET_CANCEL"]; }]];
    ALPrint(@"AL_SHEET title=%@ actions=One,Two,Cancel style=actionSheet", sheet.title);
    [self presentViewController:sheet animated:NO completion:nil];
}

@end
