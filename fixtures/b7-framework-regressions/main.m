#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#include <stdio.h>

int main(int argc, char * argv[]) {
    @autoreleasepool {
#if TARGET_OS_SIMULATOR
        // The XCUITest launches a separate app process; its stdout is not part
        // of the test runner's console log. Mirror the same protocol into the
        // app container so the workflow can export it as app-console.log.
        NSString *log = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ipa-hle-console.log"];
        freopen(log.fileSystemRepresentation, "w", stdout);
        setvbuf(stdout, NULL, _IONBF, 0);
#endif
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
