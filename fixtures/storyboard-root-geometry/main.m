#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#include <stdio.h>

int main(int argc, char * argv[]) {
    @autoreleasepool {
#if TARGET_OS_SIMULATOR
        // XCUITest launches a separate app process; its stdout is not included
        // in the test runner's console log. Four launches append to one file so
        // all mode/access combinations stay in the reference.
        NSString *log = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ipa-hle-console.log"];
        freopen(log.fileSystemRepresentation, "a", stdout);
        setvbuf(stdout, NULL, _IONBF, 0);
#endif
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
