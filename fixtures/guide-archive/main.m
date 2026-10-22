#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#include <stdio.h>

static void log_line(const char *text) {
    NSString *log = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ipa-hle-console.log"];
    FILE *file = fopen(log.fileSystemRepresentation, "a");
    if (file) {
        fprintf(file, "%s\n", text);
        fclose(file);
    }
}

static void exception_handler(NSException *exception) {
    printf("GA_EXCEPTION %s: %s\n", exception.name.UTF8String, exception.reason.UTF8String);
    fflush(stdout);
    log_line("GA_EXCEPTION logged");
}

int main(int argc, char * argv[]) {
    @autoreleasepool {
#if TARGET_OS_SIMULATOR
        NSString *log = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ipa-hle-console.log"];
        freopen(log.fileSystemRepresentation, "w", stdout);
        setvbuf(stdout, NULL, _IONBF, 0);
        NSSetUncaughtExceptionHandler(exception_handler);
        printf("GA_MAIN\n");
        fflush(stdout);
#endif
        int result = UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
        printf("GA_UIAPPLICATIONMAIN_RETURNED %d\n", result);
        fflush(stdout);
        return result;
    }
}
