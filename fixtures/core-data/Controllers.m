#import "Controllers.h"
#import <CoreData/CoreData.h>
#include <stdarg.h>
#include <stdio.h>
#import <dispatch/dispatch.h>

static void cd_line(NSString *format, ...) {
    va_list arguments;
    va_start(arguments, format);
    NSString *line = [[NSString alloc] initWithFormat:format arguments:arguments];
    va_end(arguments);
    printf("%s\n", line.UTF8String);
    fflush(stdout);
}

@interface CoreDataController ()
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic) BOOL ran;
@end

@implementation CoreDataController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.accessibilityIdentifier = @"cd.status";
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.text = @"running";
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.statusLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:20],
        [self.statusLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:40],
        [self.statusLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-20],
    ]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.ran) {
        return;
    }
    self.ran = YES;
    [self runChecks];
}

- (NSArray<NSManagedObject *> *)fetchItems:(NSManagedObjectContext *)context sorted:(BOOL)sorted
                                     error:(NSError **)error {
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"Item"];
    if (sorted) {
        fetch.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    }
    return [context executeFetchRequest:fetch error:error];
}

- (NSString *)names:(NSArray<NSManagedObject *> *)items {
    NSMutableArray *names = [NSMutableArray array];
    for (NSManagedObject *item in items) {
        [names addObject:[item valueForKey:@"name"] ?: @"nil"];
    }
    return [names componentsJoinedByString:@","];
}

- (NSString *)done:(NSArray<NSManagedObject *> *)items {
    NSMutableArray *values = [NSMutableArray array];
    for (NSManagedObject *item in items) {
        [values addObject:[[item valueForKey:@"done"] boolValue] ? @"1" : @"0"];
    }
    return [values componentsJoinedByString:@","];
}

- (BOOL)load:(NSPersistentContainer *)container callbacks:(int *)callbacks
        type:(NSString **)type error:(NSString **)errorName {
    dispatch_semaphore_t done = dispatch_semaphore_create(0);
    [container loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *description, NSError *error) {
        *callbacks += 1;
        *type = description.type ?: @"none";
        *errorName = error ? (error.domain ?: @"error") : @"none";
        dispatch_semaphore_signal(done);
    }];
    return dispatch_semaphore_wait(done, dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC)) == 0;
}

- (void)runChecks {
    NSURL *modelURL = [NSBundle.mainBundle URLForResource:@"Item" withExtension:@"momd"];
    cd_line(@"CD_MODEL present=%d name=%@", modelURL != nil, modelURL.lastPathComponent ?: @"none");

    NSPersistentContainer *container = [NSPersistentContainer persistentContainerWithName:@"Item"];
    cd_line(@"CD_CONTAINER class=%@ name=%@ viewContext=%@ descriptions=%lu",
            NSStringFromClass(container.class), container.name,
            NSStringFromClass(container.viewContext.class),
            (unsigned long)container.persistentStoreDescriptions.count);

    int callbacks = 0;
    NSString *type = @"none";
    NSString *loadError = @"none";
    BOOL loaded = [self load:container callbacks:&callbacks type:&type error:&loadError];
    cd_line(@"CD_LOAD callbacks=%d loaded=%d error=%@ stores=%lu type=%@",
            callbacks, loaded, loadError,
            (unsigned long)container.persistentStoreCoordinator.persistentStores.count, type);

    NSManagedObjectContext *context = container.viewContext;
    NSError *error = nil;
    NSUInteger existing = [context countForFetchRequest:[NSFetchRequest fetchRequestWithEntityName:@"Item"]
                                                  error:&error];
    cd_line(@"CD_START existing=%lu error=%@", (unsigned long)existing, error ? error.domain : @"none");

    if ([NSUserDefaults.standardUserDefaults boolForKey:@"CDReset"]) {
        for (NSManagedObject *item in [self fetchItems:context sorted:NO error:&error]) {
            [context deleteObject:item];
        }
        [context save:&error];
        cd_line(@"CD_RESET saved=%d error=%@", error == nil, error ? error.domain : @"none");
    }
    NSUInteger base = [context countForFetchRequest:[NSFetchRequest fetchRequestWithEntityName:@"Item"] error:&error];
    cd_line(@"CD_BASE base=%lu error=%@", (unsigned long)base, error ? error.domain : @"none");

    NSManagedObject *alpha = [NSEntityDescription insertNewObjectForEntityForName:@"Item"
                                                           inManagedObjectContext:context];
    [alpha setValue:@"Alpha" forKey:@"name"];
    [alpha setValue:@NO forKey:@"done"];
    NSManagedObject *beta = [NSEntityDescription insertNewObjectForEntityForName:@"Item"
                                                          inManagedObjectContext:context];
    [beta setValue:@"Beta" forKey:@"name"];
    [beta setValue:@YES forKey:@"done"];
    error = nil;
    BOOL saved = [context save:&error];
    cd_line(@"CD_INSERT saved=%d error=%@", saved, error ? error.domain : @"none");

    error = nil;
    NSArray<NSManagedObject *> *items = [self fetchItems:context sorted:YES error:&error];
    cd_line(@"CD_FETCH count=%lu names=%@ done=%@ error=%@",
            (unsigned long)items.count, [self names:items], [self done:items],
            error ? error.domain : @"none");

    beta = [items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == %@", @"Beta"]].firstObject;
    [beta setValue:@YES forKey:@"done"];
    error = nil;
    saved = [context save:&error];
    cd_line(@"CD_UPDATE done=%d saved=%d error=%@",
            [[beta valueForKey:@"done"] boolValue], saved, error ? error.domain : @"none");

    alpha = [items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == %@", @"Alpha"]].firstObject;
    [context deleteObject:alpha];
    error = nil;
    saved = [context save:&error];
    NSArray<NSManagedObject *> *after = [self fetchItems:context sorted:YES error:&error];
    cd_line(@"CD_DELETE count=%lu names=%@ saved=%d error=%@",
            (unsigned long)after.count, [self names:after], saved, error ? error.domain : @"none");

    NSPersistentContainer *reopened = [NSPersistentContainer persistentContainerWithName:@"Item"];
    callbacks = 0;
    type = @"none";
    loadError = @"none";
    loaded = [self load:reopened callbacks:&callbacks type:&type error:&loadError];
    error = nil;
    NSArray<NSManagedObject *> *reloaded = [self fetchItems:reopened.viewContext sorted:YES error:&error];
    cd_line(@"CD_REOPEN loaded=%d count=%lu names=%@ error=%@",
            loaded, (unsigned long)reloaded.count, [self names:reloaded],
            error ? error.domain : @"none");

    cd_line(@"CD_DONE");
    self.statusLabel.text = [NSString stringWithFormat:@"CD_DONE start=%lu count=%lu",
                             (unsigned long)existing, (unsigned long)after.count];
}

@end
