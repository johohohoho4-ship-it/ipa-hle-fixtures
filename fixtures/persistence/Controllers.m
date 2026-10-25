#import "Controllers.h"
#include <stdarg.h>
#include <stdio.h>

void PERSPrint(NSString *format, ...) {
    va_list arguments;
    va_start(arguments, format);
    NSString *line = [[NSString alloc] initWithFormat:format arguments:arguments];
    va_end(arguments);
    printf("%s\n", line.UTF8String);
    fflush(stdout);
}

@interface PersistenceController ()
@property (nonatomic, strong) UILabel *status;
@property (nonatomic) BOOL ran;
@end

@implementation PersistenceController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.status = [[UILabel alloc] init];
    self.status.accessibilityIdentifier = @"persistence.status";
    self.status.numberOfLines = 0;
    self.status.text = @"PERS_READY";
    self.status.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.status];
    [NSLayoutConstraint activateConstraints:@[
        [self.status.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:20],
        [self.status.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:40],
        [self.status.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-20],
    ]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.ran) {
        return;
    }
    self.ran = YES;
    [self runChecks];
    self.status.text = @"PERS_DONE";
}

- (void)runChecks {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    BOOL reset = [defaults boolForKey:@"PERSReset"];
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject
                      stringByAppendingPathComponent:@"note.txt"];
    NSError *error = nil;

    PERSPrint(@"PERS_START reset=%d", reset);
    NSString *beforeName = [defaults stringForKey:@"name"];
    NSInteger beforeCount = [defaults integerForKey:@"count"];
    NSString *beforeFile = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    NSUserDefaults *suite = [[NSUserDefaults alloc] initWithSuiteName:@"org.ipahle.fixture.persistence.suite"];
    PERSPrint(@"PERS_BEFORE=name=%@,count=%ld,file=%@,suite=%@",
              beforeName ?: @"nil", (long)beforeCount, beforeFile ?: @"nil",
              [suite stringForKey:@"suiteValue"] ?: @"nil");

    if (reset) {
        [defaults removePersistentDomainForName:NSBundle.mainBundle.bundleIdentifier];
        [NSFileManager.defaultManager removeItemAtPath:path error:NULL];
        PERSPrint(@"PERS_RESET=1");
    }

    [defaults registerDefaults:@{@"registered": @"fallback", @"registeredCount": @7}];
    [defaults setObject:@"alpha" forKey:@"name"];
    [defaults setInteger:42 forKey:@"count"];
    [defaults setBool:YES forKey:@"flag"];
    [defaults setDouble:1.5 forKey:@"double"];
    [defaults synchronize];
    PERSPrint(@"PERS_STANDARD=name=%@,count=%ld,flag=%d,double=%.1f,registered=%@,registeredCount=%ld",
              [defaults stringForKey:@"name"], (long)[defaults integerForKey:@"count"],
              [defaults boolForKey:@"flag"], [defaults doubleForKey:@"double"],
              [defaults stringForKey:@"registered"], (long)[defaults integerForKey:@"registeredCount"]);

    [suite setObject:@"beta" forKey:@"suiteValue"];
    [suite synchronize];
    PERSPrint(@"PERS_SUITE=%@", [suite stringForKey:@"suiteValue"] ?: @"nil");

    error = nil;
    BOOL wrote = [@"hello" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
    NSString *read = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    NSDictionary *attributes = [NSFileManager.defaultManager attributesOfItemAtPath:path error:&error];
    PERSPrint(@"PERS_FILE=wrote=%d,read=%@,size=%llu,error=%@",
              wrote, read ?: @"nil", [attributes[NSFileSize] unsignedLongLongValue],
              error ? error.domain : @"none");
    PERSPrint(@"PERS_DONE");
}

@end
