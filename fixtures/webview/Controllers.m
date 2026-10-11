#import "Controllers.h"
#include <stdio.h>

static NSString *const Page =
    @"<html><head><title>Hello</title></head><body style=\"font-family:-apple-system\">"
    @"<h2 id=\"h\">Hello</h2>"
    @"<button id=\"b\" onclick=\"window.webkit.messageHandlers.native.postMessage({n:1,s:'tap'})\">Send</button>"
    @"</body></html>";

@interface WebController ()
@property (nonatomic, strong) WKWebView *web;
@property (nonatomic, strong) UILabel *result;
@property (nonatomic, strong) UIView *last;
@end

@implementation WebController

- (UIButton *)button:(NSString *)title identifier:(NSString *)identifier action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(20, self.last ? CGRectGetMaxY(self.last.frame) + 6 : 400, 200, 36);
    [button setTitle:title forState:UIControlStateNormal];
    button.accessibilityIdentifier = identifier;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    self.last = button;
    return button;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    [config.userContentController addScriptMessageHandler:self name:@"native"];
    WKUserScript *script = [[WKUserScript alloc] initWithSource:@"window.fromUserScript = 'yes';"
                                                  injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                               forMainFrameOnly:YES];
    [config.userContentController addUserScript:script];
    self.web = [[WKWebView alloc] initWithFrame:CGRectMake(20, 80, 350, 260) configuration:config];
    self.web.navigationDelegate = self;
    self.web.accessibilityIdentifier = @"wv.web";
    [self.view addSubview:self.web];
    self.result = [[UILabel alloc] initWithFrame:CGRectMake(20, 350, 350, 30)];
    self.result.text = @"idle";
    self.result.accessibilityIdentifier = @"wv.label";
    [self.view addSubview:self.result];
    [self button:@"Eval sum" identifier:@"wv.sum" action:@selector(sum)];
    [self button:@"Eval title" identifier:@"wv.title" action:@selector(evalTitle)];
    [self button:@"Eval user script" identifier:@"wv.user" action:@selector(user)];
    [self button:@"Eval json" identifier:@"wv.json" action:@selector(json)];
    [self button:@"Eval undefined" identifier:@"wv.undef" action:@selector(undef)];
    [self button:@"Eval throw" identifier:@"wv.throw" action:@selector(thrower)];
    [self.web loadHTMLString:Page baseURL:nil];
    printf("WV_EVENT load requested loading=%d\n", self.web.isLoading);
}

- (void)evaluate:(NSString *)script name:(const char *)name {
    [self.web evaluateJavaScript:script completionHandler:^(id value, NSError *error) {
        if (error) {
            printf("WV_EVENT eval %s error domain=%s code=%ld\n", name, error.domain.UTF8String, (long)error.code);
            self.result.text = @"error";
        } else if (!value) {
            printf("WV_EVENT eval %s nil\n", name);
            self.result.text = @"nil";
        } else if ([value isKindOfClass:NSNumber.class]) {
            printf("WV_EVENT eval %s number %d\n", name, [value intValue]);
            self.result.text = [NSString stringWithFormat:@"%d", [value intValue]];
        } else if ([value isKindOfClass:NSString.class]) {
            printf("WV_EVENT eval %s string %s\n", name, [value UTF8String]);
            self.result.text = value;
        } else if ([value isKindOfClass:NSDictionary.class]) {
            NSArray *list = value[@"a"];
            printf("WV_EVENT eval %s dictionary count=%lu a=%lu first=%d\n", name, (unsigned long)[value count],
                   (unsigned long)list.count, [list.firstObject intValue]);
            self.result.text = @"dictionary";
        } else {
            printf("WV_EVENT eval %s other\n", name);
        }
    }];
}

- (void)sum { [self evaluate:@"1 + 2" name:"sum"]; }
- (void)evalTitle { [self evaluate:@"document.title" name:"title"]; }
- (void)user { [self evaluate:@"window.fromUserScript" name:"user"]; }
- (void)json { [self evaluate:@"({a: [1, 'x', null, true]})" name:"json"]; }
- (void)undef { [self evaluate:@"void 0" name:"undef"]; }
- (void)thrower { [self evaluate:@"throw new Error('boom')" name:"throw"]; }

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    printf("WV_EVENT delegate start loading=%d\n", webView.isLoading);
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    printf("WV_EVENT delegate commit\n");
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    printf("WV_EVENT delegate finish loading=%d title=%s\n", webView.isLoading, webView.title.UTF8String);
    self.result.text = @"loaded";
}

- (void)userContentController:(WKUserContentController *)controller didReceiveScriptMessage:(WKScriptMessage *)message {
    NSDictionary *body = message.body;
    printf("WV_EVENT message name=%s n=%d s=%s\n", message.name.UTF8String, [body[@"n"] intValue], [body[@"s"] UTF8String]);
    self.result.text = [NSString stringWithFormat:@"message %@", body[@"s"]];
}

@end
