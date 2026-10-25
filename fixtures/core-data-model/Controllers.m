#import "Controllers.h"
#import <CoreData/CoreData.h>
#include <stdarg.h>
#include <stdio.h>
#import <dispatch/dispatch.h>
#import <sqlite3.h>

static void cd_line(NSString *format, ...) {
    va_list arguments;
    va_start(arguments, format);
    NSString *line = [[NSString alloc] initWithFormat:format arguments:arguments];
    va_end(arguments);
    printf("%s\n", line.UTF8String);
    fflush(stdout);
}

static NSString *cdm_type_name(NSAttributeType type) {
    switch (type) {
        case NSInteger16AttributeType: return @"Integer16";
        case NSInteger32AttributeType: return @"Integer32";
        case NSInteger64AttributeType: return @"Integer64";
        case NSDecimalAttributeType: return @"Decimal";
        case NSDoubleAttributeType: return @"Double";
        case NSFloatAttributeType: return @"Float";
        case NSStringAttributeType: return @"String";
        case NSBooleanAttributeType: return @"Boolean";
        case NSDateAttributeType: return @"Date";
        case NSBinaryDataAttributeType: return @"Binary";
        case NSUUIDAttributeType: return @"UUID";
        case NSURIAttributeType: return @"URI";
        case NSTransformableAttributeType: return @"Transformable";
        case NSObjectIDAttributeType: return @"ObjectID";
        default: return [NSString stringWithFormat:@"%lu", (unsigned long)type];
    }
}

static NSString *cdm_default(NSAttributeDescription *attribute) {
    id value = attribute.defaultValue;
    if (!value) {
        return @"none";
    }
    return [NSString stringWithFormat:@"%@:%@", NSStringFromClass([value class]), value];
}

static NSString *cdm_sql_dump(NSURL *url) {
    if (!url) {
        return @"CDM_SQL=no-url\n";
    }
    sqlite3 *db = NULL;
    if (sqlite3_open_v2(url.path.UTF8String, &db, SQLITE_OPEN_READONLY, NULL) != SQLITE_OK) {
        NSString *reason = db ? [NSString stringWithUTF8String:sqlite3_errmsg(db)] : @"open";
        if (db) {
            sqlite3_close(db);
        }
        return [NSString stringWithFormat:@"CDM_SQL=error:%@\n", reason];
    }
    NSMutableString *result = [NSMutableString string];
    sqlite3_stmt *statement = NULL;
    NSMutableArray<NSString *> *tables = [NSMutableArray array];
    if (sqlite3_prepare_v2(db, "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name", -1,
                           &statement, NULL) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            const unsigned char *name = sqlite3_column_text(statement, 0);
            if (name) {
                [tables addObject:[NSString stringWithUTF8String:(const char *)name]];
            }
        }
    }
    sqlite3_finalize(statement);
    [result appendFormat:@"CDM_SQL_TABLES=%@\n", [tables componentsJoinedByString:@","]];
    NSMutableArray<NSString *> *info = [NSMutableArray array];
    for (NSString *table in tables) {
        NSString *sql = [NSString stringWithFormat:@"PRAGMA table_info(\"%@\")", table];
        if (sqlite3_prepare_v2(db, sql.UTF8String, -1, &statement, NULL) != SQLITE_OK) {
            continue;
        }
        while (sqlite3_step(statement) == SQLITE_ROW) {
            const unsigned char *name = sqlite3_column_text(statement, 1);
            const unsigned char *type = sqlite3_column_text(statement, 2);
            const unsigned char *fallback = sqlite3_column_text(statement, 4);
            [info addObject:[NSString stringWithFormat:@"%@:%s:%s:%d:%s:%d", table,
                             name ? (const char *)name : "", type ? (const char *)type : "",
                             sqlite3_column_int(statement, 3),
                             fallback ? (const char *)fallback : "",
                             sqlite3_column_int(statement, 5)]];
        }
        sqlite3_finalize(statement);
    }
    [result appendFormat:@"CDM_SQL_INFO=%@\n", [info componentsJoinedByString:@";"]];
    if (sqlite3_prepare_v2(db, "SELECT Z_VERSION, Z_UUID, length(Z_PLIST) FROM Z_METADATA", -1,
                           &statement, NULL) == SQLITE_OK) {
        NSMutableArray<NSString *> *rows = [NSMutableArray array];
        while (sqlite3_step(statement) == SQLITE_ROW) {
            const unsigned char *uuid = sqlite3_column_text(statement, 1);
            [rows addObject:[NSString stringWithFormat:@"Z_VERSION:%d,Z_UUID:%s,Z_PLIST_BYTES:%d",
                             sqlite3_column_int(statement, 0), uuid ? (const char *)uuid : "",
                             sqlite3_column_int(statement, 2)]];
        }
        [result appendFormat:@"CDM_SQL_METADATA=%@\n", [rows componentsJoinedByString:@";"]];
        sqlite3_finalize(statement);
    } else {
        [result appendString:@"CDM_SQL_METADATA=none\n"];
    }
    if (sqlite3_prepare_v2(db, "SELECT Z_ENT, Z_NAME, Z_SUPER, Z_MAX FROM Z_PRIMARYKEY ORDER BY Z_ENT", -1,
                           &statement, NULL) == SQLITE_OK) {
        NSMutableArray<NSString *> *rows = [NSMutableArray array];
        while (sqlite3_step(statement) == SQLITE_ROW) {
            const unsigned char *name = sqlite3_column_text(statement, 1);
            [rows addObject:[NSString stringWithFormat:@"%d:%s:%d:%d", sqlite3_column_int(statement, 0),
                             name ? (const char *)name : "", sqlite3_column_int(statement, 2),
                             sqlite3_column_int(statement, 3)]];
        }
        [result appendFormat:@"CDM_SQL_PRIMARYKEY=%@\n", [rows componentsJoinedByString:@";"]];
        sqlite3_finalize(statement);
    } else {
        [result appendString:@"CDM_SQL_PRIMARYKEY=none\n"];
    }
    sqlite3_close(db);
    return result;
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

    NSManagedObjectModel *model = container.managedObjectModel;
    cd_line(@"CDM_MODEL=entities=%lu", (unsigned long)model.entities.count);
    NSMutableArray<NSString *> *entityNames = [NSMutableArray array];
    for (NSEntityDescription *entity in [model.entities sortedArrayUsingComparator:^NSComparisonResult(NSEntityDescription *a, NSEntityDescription *b) {
        return [a.name compare:b.name];
    }]) {
        [entityNames addObject:[NSString stringWithFormat:@"%@,class=%@", entity.name, entity.managedObjectClassName]];
        for (NSPropertyDescription *property in entity.properties) {
            if ([property isKindOfClass:NSAttributeDescription.class]) {
                NSAttributeDescription *attribute = (NSAttributeDescription *)property;
                cd_line(@"CDM_ATTR=%@,%@,type=%@,optional=%d,transient=%d,default=%@,valueClass=%@",
                        entity.name, attribute.name, cdm_type_name(attribute.attributeType),
                        attribute.isOptional, attribute.isTransient, cdm_default(attribute),
                        attribute.attributeValueClassName ?: @"none");
            } else if ([property isKindOfClass:NSRelationshipDescription.class]) {
                NSRelationshipDescription *relationship = (NSRelationshipDescription *)property;
                cd_line(@"CDM_REL=%@,%@,to=%@,toMany=%d,inverse=%@,optional=%d,deleteRule=%lu",
                        entity.name, relationship.name, relationship.destinationEntity.name,
                        relationship.isToMany, relationship.inverseRelationship.name ?: @"none",
                        relationship.isOptional, (unsigned long)relationship.deleteRule);
            }
        }
    }
    cd_line(@"CDM_ENTITY=%@", [entityNames componentsJoinedByString:@";"]);

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

    NSEntityDescription *itemEntity = model.entitiesByName[@"Item"];
    NSAttributeDescription *amountAttribute = itemEntity.attributesByName[@"amount"];
    NSAttributeDescription *requiredAttribute = itemEntity.attributesByName[@"requiredName"];
    id amountValue = [alpha valueForKey:@"amount"];
    id requiredValue = [alpha valueForKey:@"requiredName"];
    cd_line(@"CDM_DEFAULT=amount:class=%@,value=%@,optional=%d;requiredName:class=%@,value=%@,optional=%d",
            NSStringFromClass([amountValue class]), amountValue ?: @"nil", amountAttribute.isOptional,
            NSStringFromClass([requiredValue class]), requiredValue ?: @"nil", requiredAttribute.isOptional);

    NSManagedObject *tag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag"
                                                         inManagedObjectContext:context];
    [tag setValue:@"t1" forKey:@"name"];
    [tag setValue:beta forKey:@"item"];
    error = nil;
    BOOL relationshipSaved = [context save:&error];
    cd_line(@"CDM_RELATION=tag.item=%@,beta.tags=%lu,saved=%d,error=%@",
            [[tag valueForKey:@"item"] valueForKey:@"name"] ?: @"nil",
            (unsigned long)[[beta valueForKey:@"tags"] count], relationshipSaved,
            error ? error.domain : @"none");

    NSURL *storeURL = container.persistentStoreCoordinator.persistentStores.firstObject.URL;
    cd_line(@"CDM_STORE=%@", storeURL.lastPathComponent ?: @"none");
    printf("%s", cdm_sql_dump(storeURL).UTF8String);
    fflush(stdout);

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

    error = nil;
    NSArray<NSManagedObject *> *tags = [reopened.viewContext executeFetchRequest:[NSFetchRequest fetchRequestWithEntityName:@"Tag"]
                                                                           error:&error];
    NSMutableArray<NSString *> *links = [NSMutableArray array];
    for (NSManagedObject *tag in tags) {
        [links addObject:[NSString stringWithFormat:@"%@->%@", [tag valueForKey:@"name"],
                          [[tag valueForKey:@"item"] valueForKey:@"name"] ?: @"nil"]];
    }
    cd_line(@"CDM_REOPEN_RELATION=tags=%lu,links=%@,error=%@",
            (unsigned long)tags.count, [links componentsJoinedByString:@","],
            error ? error.domain : @"none");
    NSManagedObject *first = reloaded.firstObject;
    cd_line(@"CDM_REOPEN_DEFAULT=amount=%@,requiredName=%@",
            [first valueForKey:@"amount"] ?: @"nil", [first valueForKey:@"requiredName"] ?: @"nil");

    cd_line(@"CD_DONE");
    self.statusLabel.text = [NSString stringWithFormat:@"CD_DONE start=%lu count=%lu",
                             (unsigned long)existing, (unsigned long)after.count];
}

@end
