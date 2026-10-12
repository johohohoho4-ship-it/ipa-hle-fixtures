#import <UIKit/UIKit.h>
#import <TargetConditionals.h>
#import "AppDelegate.h"
#include <stdio.h>

int main(int argc, char * argv[]) {
    @autoreleasepool {
#if TARGET_OS_SIMULATOR
        // The collector reads this file from the app container after XCUITest.
        NSString *log = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ipa-hle-console.log"];
        if (freopen(log.fileSystemRepresentation, "w", stdout)) {
            setvbuf(stdout, NULL, _IONBF, 0);
        } else {
            perror("pthread-lifecycle: simulator console redirect");
        }
#endif
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
