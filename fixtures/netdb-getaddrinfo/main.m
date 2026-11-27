#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#include <stdio.h>

int main(int argc, char * argv[]) {
    @autoreleasepool {
#if TARGET_OS_SIMULATOR
        NSString *log = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ipa-hle-console.log"];
        freopen(log.fileSystemRepresentation, "w", stdout);
        setvbuf(stdout, NULL, _IONBF, 0);
#endif
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
