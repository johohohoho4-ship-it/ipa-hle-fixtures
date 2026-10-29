#import <UIKit/UIKit.h>
#import <TargetConditionals.h>

static void CLL(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *line = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    printf("%s\n", line.UTF8String);
    fflush(stdout);
}

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow *window;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#if TARGET_OS_SIMULATOR
    NSString *log = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ipa-hle-console.log"];
    freopen(log.UTF8String, "w", stdout);
    setvbuf(stdout, NULL, _IONBF, 0);
#endif

    NSArray *array = @[@"b", @"d", @"a", @"c"];
    CLL(@"CLL_ARRAY count=%lu index=%lu contains=%d joined=%@",
        (unsigned long)array.count, (unsigned long)[array indexOfObject:@"a"],
        [array containsObject:@"d"], [array componentsJoinedByString:@"|"]);
    NSArray *sorted = [array sortedArrayUsingSelector:@selector(compare:)];
    CLL(@"CLL_SORTED %@", [sorted componentsJoinedByString:@","]);
    NSArray *byBlock = [array sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        return [b compare:a];
    }];
    CLL(@"CLL_SORTED_BLOCK %@", [byBlock componentsJoinedByString:@","]);
    NSArray *sub = [array subarrayWithRange:NSMakeRange(1, 2)];
    CLL(@"CLL_SUB %@", [sub componentsJoinedByString:@","]);

    NSMutableArray *mutable = [array mutableCopy];
    [mutable addObject:@"e"];
    [mutable insertObject:@"x" atIndex:1];
    [mutable removeObjectAtIndex:3];
    [mutable replaceObjectAtIndex:0 withObject:@"z"];
    [mutable exchangeObjectAtIndex:0 withObjectAtIndex:1];
    [mutable removeLastObject];
    CLL(@"CLL_MUTABLE count=%lu %@", (unsigned long)mutable.count,
        [mutable componentsJoinedByString:@","]);

    NSDictionary *dictionary = @{@"b": @2, @"a": @1};
    NSArray *keys = [[dictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
    CLL(@"CLL_DICT count=%lu keys=%@ value=%@ missing=%@",
        (unsigned long)dictionary.count, [keys componentsJoinedByString:@","],
        dictionary[@"a"], dictionary[@"zz"] ?: @"nil");
    NSMutableArray *pairs = [NSMutableArray array];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
    }];
    [pairs sortUsingSelector:@selector(compare:)];
    CLL(@"CLL_ENUM %@", [pairs componentsJoinedByString:@","]);
    NSMutableDictionary *mutableDictionary = [dictionary mutableCopy];
    [mutableDictionary setObject:@3 forKey:@"c"];
    [mutableDictionary removeObjectForKey:@"b"];
    NSArray *mutableKeys = [[mutableDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
    CLL(@"CLL_MUTABLE_DICT count=%lu keys=%@", (unsigned long)mutableDictionary.count,
        [mutableKeys componentsJoinedByString:@","]);

    NSSet *first = [NSSet setWithObjects:@1, @2, nil];
    NSSet *second = [NSSet setWithObjects:@2, @3, nil];
    NSArray *unionKeys = [[[first setByAddingObjectsFromSet:second] allObjects]
        sortedArrayUsingSelector:@selector(compare:)];
    NSMutableSet *intersection = [first mutableCopy];
    [intersection intersectSet:second];
    NSMutableSet *minus = [first mutableCopy];
    [minus minusSet:second];
    CLL(@"CLL_SET union=%@ intersect=%@ minus=%@ subset=%d member=%d",
        [unionKeys componentsJoinedByString:@","],
        [[[intersection allObjects] sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@","],
        [[[minus allObjects] sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@","],
        [first isSubsetOfSet:[NSSet setWithObjects:@1, @2, @3, nil]],
        [first containsObject:@2]);

    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(2, 3)];
    CLL(@"CLL_INDEXSET count=%lu contains2=%d contains9=%d first=%lu",
        (unsigned long)indexSet.count, [indexSet containsIndex:2], [indexSet containsIndex:9],
        (unsigned long)indexSet.firstIndex);

    NSIndexPath *path = [NSIndexPath indexPathForRow:5 inSection:2];
    CLL(@"CLL_INDEXPATH section=%ld row=%ld", (long)path.section, (long)path.row);

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    label.text = @"Collections";
    label.accessibilityIdentifier = "collections.title";
    label.textAlignment = NSTextAlignmentCenter;

    UIViewController *controller = [[UIViewController alloc] init];
    controller.view.backgroundColor = [UIColor whiteColor];
    label.center = CGPointMake(195, 422);
    [controller.view addSubview:label];

    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = controller;
    [self.window makeKeyAndVisible];
    return YES;
}

@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
