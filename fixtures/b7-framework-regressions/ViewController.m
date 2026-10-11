#import "ViewController.h"

#import <CoreFoundation/CoreFoundation.h>
#import <dispatch/dispatch.h>
#import <objc/runtime.h>
#import <sqlite3.h>
#include <stdint.h>
#import <string.h>
#import <unistd.h>

static void B7Write(NSString *line) {
    NSData *data = [[line stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding];
    if (data.length) {
        (void)write(STDOUT_FILENO, data.bytes, data.length);
    }
}

static NSMutableArray<NSString *> *B7FailureDetails;

static BOOL B7Check(NSString *name, BOOL ok, NSString *detail) {
    NSString *line = [NSString stringWithFormat:@"%@=%@%@", name, ok ? @"ok" : @"FAIL", detail.length ? [@" " stringByAppendingString:detail] : @""];
    B7Write(line);
    if (!ok) [B7FailureDetails addObject:line];
    return ok;
}

@interface B7MemoryProbe : NSObject
+ (instancetype)autoreleasedProbe;
- (void)performAsyncOnQueue:(dispatch_queue_t)queue
              startedSignal:(dispatch_semaphore_t)started
            completionGate:(dispatch_semaphore_t)gate;
@end

@implementation B7MemoryProbe
+ (instancetype)autoreleasedProbe {
    return [[self alloc] init];
}

- (void)performAsyncOnQueue:(dispatch_queue_t)queue
              startedSignal:(dispatch_semaphore_t)started
            completionGate:(dispatch_semaphore_t)gate {
    dispatch_async(queue, ^{
        (void)[self class];
        dispatch_semaphore_signal(started);
        dispatch_semaphore_wait(gate, DISPATCH_TIME_FOREVER);
        B7Write(@"D2_BLOCK_CAPTURE=executed");
    });
}

- (void)dealloc {
    B7Write(@"D2_DEALLOC=observed");
}
@end

@interface B7ObservationProbe : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) B7ObservationProbe *child;
@property (nonatomic) NSInteger age;
@property (nonatomic) double score;
@property (nonatomic) NSInteger manualValue;
@end

@implementation B7ObservationProbe
@synthesize manualValue = _manualValue;

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    if ([key isEqualToString:@"manualValue"]) {
        return NO;
    }
    return [super automaticallyNotifiesObserversForKey:key];
}

- (void)setManualValue:(NSInteger)value {
    [self willChangeValueForKey:@"manualValue"];
    _manualValue = value;
    [self didChangeValueForKey:@"manualValue"];
}
@end

@interface B7Observer : NSObject
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *changes;
@end

@implementation B7Observer
- (instancetype)init {
    self = [super init];
    if (self) {
        _changes = [NSMutableArray array];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
    (void)object;
    (void)context;
    NSMutableDictionary *record = [change mutableCopy];
    record[@"b7.keyPath"] = keyPath;
    [self.changes addObject:record];
}
@end

@interface B7Node : NSObject <NSSecureCoding>
@property (nonatomic, strong) B7Node *next;
@end

@implementation B7Node
+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.next forKey:@"next"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _next = [coder decodeObjectOfClass:[B7Node class] forKey:@"next"];
    }
    return self;
}
@end

static BOOL B7TestMemoryManagement(void) {
    __weak B7MemoryProbe *weakAutoreleased = nil;
    @autoreleasepool {
        B7MemoryProbe *probe = [B7MemoryProbe autoreleasedProbe];
        weakAutoreleased = probe;
        probe = nil;
    }
    BOOL poolReleased = weakAutoreleased == nil;

    NSObject *owner = [NSObject new];
    B7MemoryProbe *associated = [B7MemoryProbe new];
    __weak B7MemoryProbe *weakAssociated = associated;
    static char associationKey;
    objc_setAssociatedObject(owner, &associationKey, associated, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    associated = nil;
    BOOL associationRetained = weakAssociated != nil;
    objc_setAssociatedObject(owner, &associationKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    owner = nil;
    BOOL associationReleased = weakAssociated == nil;

    NSMutableArray *items = [NSMutableArray array];
    B7MemoryProbe *item = [B7MemoryProbe new];
    __weak B7MemoryProbe *weakItem = item;
    [items addObject:item];
    item = nil;
    [items removeAllObjects];
    BOOL arrayReleased = weakItem == nil;

    dispatch_queue_t queue = dispatch_queue_create("org.ipahle.fixture.b7.capture", DISPATCH_QUEUE_SERIAL);
    dispatch_semaphore_t started = dispatch_semaphore_create(0);
    dispatch_semaphore_t gate = dispatch_semaphore_create(0);
    B7MemoryProbe *captured = [B7MemoryProbe new];
    __weak B7MemoryProbe *weakCaptured = captured;
    [captured performAsyncOnQueue:queue startedSignal:started completionGate:gate];
    BOOL blockStarted = dispatch_semaphore_wait(started, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC)) == 0;
    captured = nil;
    BOOL retainedDuringBlock = weakCaptured != nil;
    dispatch_semaphore_signal(gate);
    dispatch_sync(queue, ^{});
    BOOL releasedAfterBlock = weakCaptured == nil;

    return B7Check(@"D2", poolReleased && associationRetained && associationReleased && arrayReleased &&
                   blockStarted && retainedDuringBlock && releasedAfterBlock,
                   [NSString stringWithFormat:@"pool=%d association=%d/%d array=%d block=%d retained=%d released=%d",
                    poolReleased, associationRetained, associationReleased, arrayReleased, blockStarted,
                    retainedDuringBlock, releasedAfterBlock]);
}

static BOOL B7TestKeyValueAndObservation(void) {
    B7ObservationProbe *probe = [B7ObservationProbe new];
    probe.age = 18;
    probe.score = 1.5;
    probe.manualValue = 6;
    B7ObservationProbe *child = [B7ObservationProbe new];
    child.name = @"Mila";
    probe.child = child;
    B7Observer *observer = [B7Observer new];
    NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld |
        NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionPrior;
    [probe addObserver:observer forKeyPath:@"name" options:options context:NULL];
    [probe addObserver:observer forKeyPath:@"age" options:options context:NULL];
    [probe addObserver:observer forKeyPath:@"score" options:options context:NULL];
    [probe addObserver:observer forKeyPath:@"manualValue" options:options context:NULL];
    [probe setValue:@"Ada" forKey:@"name"];
    [probe setValue:@31 forKey:@"age"];
    [probe setValue:@4.25 forKey:@"score"];
    [probe setValue:@7 forKey:@"manualValue"];
    NSString *nestedName = [probe valueForKeyPath:@"child.name"];

    BOOL sawPrior = NO;
    BOOL sawOld = NO;
    BOOL sawNew = NO;
    BOOL sawInitialAge = NO;
    BOOL sawManualInitial = NO;
    BOOL sawManualPrior = NO;
    BOOL sawManualNewValue = NO;
    NSUInteger manualChanges = 0;
    for (NSDictionary *change in observer.changes) {
        BOOL prior = [change[NSKeyValueChangeNotificationIsPriorKey] boolValue];
        sawPrior |= prior;
        sawOld |= change[NSKeyValueChangeOldKey] != nil;
        sawNew |= change[NSKeyValueChangeNewKey] != nil;
        if ([change[@"b7.keyPath"] isEqualToString:@"age"] &&
            [change[NSKeyValueChangeNewKey] integerValue] == 18) {
            sawInitialAge = YES;
        }
        if ([change[@"b7.keyPath"] isEqualToString:@"manualValue"]) {
            sawManualPrior |= prior;
            if (!prior && [change[NSKeyValueChangeNewKey] integerValue] == 6) {
                sawManualInitial = YES;
            } else {
                manualChanges++;
                sawManualNewValue |= !prior && [change[NSKeyValueChangeNewKey] integerValue] == 7;
            }
        }
    }

    BOOL unknownKeyRaised = NO;
    @try {
        (void)[probe valueForKey:@"unknownB7Key"];
    } @catch (NSException *exception) {
        unknownKeyRaised = [exception.name isEqualToString:NSUndefinedKeyException];
    }

    [probe removeObserver:observer forKeyPath:@"name"];
    [probe removeObserver:observer forKeyPath:@"age"];
    [probe removeObserver:observer forKeyPath:@"score"];
    [probe removeObserver:observer forKeyPath:@"manualValue"];
    BOOL ok = [probe.name isEqualToString:@"Ada"] && probe.age == 31 && probe.score == 4.25 &&
        probe.manualValue == 7 && [nestedName isEqualToString:@"Mila"] && sawPrior && sawOld && sawNew &&
        sawInitialAge && sawManualInitial && manualChanges == 2 && sawManualPrior && sawManualNewValue && unknownKeyRaised;
    return B7Check(@"D3", ok, [NSString stringWithFormat:@"observations=%lu prior=%d old=%d new=%d initial=%d manual=%lu/%d/%d/%d unknown=%d",
                               (unsigned long)observer.changes.count, sawPrior, sawOld, sawNew, sawInitialAge,
                               (unsigned long)manualChanges, sawManualInitial, sawManualPrior, sawManualNewValue,
                               unknownKeyRaised]);
}

static BOOL B7TestStrings(void) {
    NSString *unicode = @"ä😀";
    unichar high = [unicode characterAtIndex:1];
    unichar low = [unicode characterAtIndex:2];
    NSString *family = @"👨‍👩‍👧‍👦";
    BOOL familyUTF16 = family.length == 11 && [family rangeOfComposedCharacterSequenceAtIndex:0].length == 11 &&
        [family characterAtIndex:2] == 0x200D && [family characterAtIndex:5] == 0x200D &&
        [family characterAtIndex:8] == 0x200D;
    BOOL utf16 = unicode.length == 3 && [unicode characterAtIndex:0] == 0x00E4 &&
        high >= 0xD800 && high <= 0xDBFF && low >= 0xDC00 && low <= 0xDFFF && familyUTF16;
    NSData *utf16Bytes = [unicode dataUsingEncoding:NSUTF16LittleEndianStringEncoding];

    NSRange folded = [@"Straße" rangeOfString:@"STRASSE" options:NSCaseInsensitiveSearch];
    NSRange diacritics = [@"café" rangeOfString:@"cafe" options:NSDiacriticInsensitiveSearch];
    NSRange backwards = [@"one two one" rangeOfString:@"one" options:NSBackwardsSearch];
    NSRange regex = [@"42abc" rangeOfString:@"^[0-9]+" options:NSRegularExpressionSearch];
    NSArray *localizedSort = [@[@"zebra", @"apfel", @"birne"] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
    NSString *latin = @"café";
    NSData *latinBytes = [latin dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:NO];
    const uint8_t expectedLatin[] = {0x63, 0x61, 0x66, 0xE9};
    BOOL encodings = utf16Bytes.length == 6 && memcmp(utf16Bytes.bytes, "\xE4\0", 2) == 0 &&
        latinBytes.length == sizeof(expectedLatin) && memcmp(latinBytes.bytes, expectedLatin, sizeof(expectedLatin)) == 0;
    NSString *formatted = [NSString stringWithFormat:@"%@ %@", @[@"one", @"two"], @{ @"name": @"Ada" }];
    NSString *escaped = [@"a b" stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPathAllowedCharacterSet];
    BOOL intValueOK = [@"42abc" intValue] == 42;
    BOOL escapedOK = [escaped containsString:@"%20"];

    UIColor *red = [UIColor redColor];
    UIColor *blue = [UIColor blueColor];
    NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] initWithString:@"ab"
        attributes:@{ NSForegroundColorAttributeName: red }];
    [attributed addAttribute:NSForegroundColorAttributeName value:blue range:NSMakeRange(1, 1)];
    __block NSUInteger runs = 0;
    __block BOOL hasForeground = NO;
    __block BOOL hasRedRun = NO;
    __block BOOL hasBlueRun = NO;
    [attributed enumerateAttributesInRange:NSMakeRange(0, attributed.length) options:0
        usingBlock:^(NSDictionary<NSAttributedStringKey, id> *attributes, NSRange range, BOOL *stop) {
            (void)stop;
            runs++;
            hasForeground |= attributes[NSForegroundColorAttributeName] != nil;
            hasRedRun |= range.location == 0 && range.length == 1 && attributes[NSForegroundColorAttributeName] == red;
            hasBlueRun |= range.location == 1 && range.length == 1 && attributes[NSForegroundColorAttributeName] == blue;
        }];

    NSURLComponents *components = [NSURLComponents componentsWithString:@"https://example.invalid/path"];
    components.queryItems = @[[NSURLQueryItem queryItemWithName:@"city" value:@"München"]];
    BOOL queryRoundTrips = [components.queryItems.firstObject.value isEqualToString:@"München"] &&
        [components.percentEncodedQuery containsString:@"%C3%BC"];
    BOOL localizedOrder = [localizedSort isEqualToArray:@[@"apfel", @"birne", @"zebra"]];
    BOOL formattedValues = [formatted containsString:@"one"] && [formatted containsString:@"Ada"];
    BOOL ok = utf16 && encodings && folded.location == 0 && folded.length == 6 && diacritics.location == 0 &&
        diacritics.length == 4 && backwards.location == 8 && localizedOrder && regex.location == 0 && regex.length == 2 &&
        latinBytes.length == 4 && intValueOK && formatted.length > 0 &&
        formattedValues && escapedOK && runs == 2 && hasForeground &&
        hasRedRun && hasBlueRun && queryRoundTrips;
    return B7Check(@"D4", ok, [NSString stringWithFormat:@"utf16=%d family=%d encodings=%d fold=%lu/%lu diacritics=%lu/%lu backwards=%lu localized=%d regex=%lu/%lu latin=%lu runs=%lu attributed=%d intValue=%d formattedValues=%d escaped=%@ escapedOK=%d queryRoundTrips=%d",
                               utf16, familyUTF16, encodings, (unsigned long)folded.location, (unsigned long)folded.length,
                               (unsigned long)diacritics.location, (unsigned long)diacritics.length,
                               (unsigned long)backwards.location, localizedOrder,
                               (unsigned long)regex.location, (unsigned long)regex.length,
                               (unsigned long)latinBytes.length, (unsigned long)runs, hasForeground,
                               intValueOK, formattedValues, escaped ?: @"<nil>", escapedOK, queryRoundTrips]);
}

static BOOL B7TestCollections(void) {
    NSArray<NSNumber *> *values = @[@3, @1, @2];
    NSArray *bySelector = [values sortedArrayUsingSelector:@selector(compare:)];
    NSArray *byBlock = [values sortedArrayUsingComparator:^NSComparisonResult(NSNumber *left, NSNumber *right) {
        return [left compare:right];
    }];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    NSArray *byDescriptor = [values sortedArrayUsingDescriptors:@[descriptor]];
    __block NSUInteger visited = 0;
    [values enumerateObjectsUsingBlock:^(NSNumber *object, NSUInteger index, BOOL *stop) {
        (void)object;
        visited++;
        if (index == 1) {
            *stop = YES;
        }
    }];

    NSSet *left = [NSSet setWithArray:@[@1, @2]];
    NSSet *right = [NSSet setWithArray:@[@2, @3]];
    NSMutableSet *united = [NSMutableSet setWithSet:left];
    [united unionSet:right];
    NSMutableSet *intersected = [NSMutableSet setWithSet:left];
    [intersected intersectSet:right];
    NSMutableSet *minus = [NSMutableSet setWithSet:left];
    [minus minusSet:right];
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(2, 3)];
    NSDictionary *dictionary = @{ @"one": @1, @"two": @2 };
    __block NSUInteger enumeratedKeys = 0;
    for (id key in dictionary) {
        (void)key;
        enumeratedKeys++;
    }
    NSMutableArray *mutable = [NSMutableArray arrayWithArray:values];
    [mutable removeAllObjects];

    BOOL ok = [bySelector isEqual:@[@1, @2, @3]] && [byBlock isEqual:bySelector] &&
        [byDescriptor isEqual:bySelector] && visited == 2 && united.count == 3 &&
        intersected.count == 1 && minus.count == 1 && indexes.count == 3 && indexes.firstIndex == 2 &&
        enumeratedKeys == 2 && mutable.count == 0;
    return B7Check(@"D5", ok, [NSString stringWithFormat:@"visited=%lu union=%lu intersection=%lu keys=%lu",
                               (unsigned long)visited, (unsigned long)united.count,
                               (unsigned long)intersected.count, (unsigned long)enumeratedKeys]);
}

static BOOL B7TestSerialization(void) {
    NSError *error = nil;
    NSArray *array = @[@"one", @2, @{ @"key": @"value" }];
    NSData *json = [NSJSONSerialization dataWithJSONObject:array options:NSJSONWritingPrettyPrinted error:&error];
    NSArray *jsonRoundTrip = json ? [NSJSONSerialization JSONObjectWithData:json options:0 error:&error] : nil;
    NSData *compactJSON = [NSJSONSerialization dataWithJSONObject:array options:0 error:&error];
    BOOL pretty = json && compactJSON && json.length > compactJSON.length;
    BOOL jsonOK = [jsonRoundTrip isEqual:array] && pretty;

    NSDictionary *plist = @{ @"name": @"Ada", @"items": @[@1, @2] };
    NSPropertyListFormat formats[] = { NSPropertyListXMLFormat_v1_0, NSPropertyListBinaryFormat_v1_0 };
    BOOL plistOK = YES;
    for (NSUInteger index = 0; index < 2; index++) {
        error = nil;
        NSData *data = [NSPropertyListSerialization dataWithPropertyList:plist format:formats[index]
            options:0 error:&error];
        NSPropertyListFormat readFormat = NSPropertyListOpenStepFormat;
        NSDictionary *roundTrip = data ? [NSPropertyListSerialization propertyListWithData:data options:0
            format:&readFormat error:&error] : nil;
        plistOK &= [roundTrip isEqual:plist] && readFormat == formats[index];
    }

    B7Node *root = [B7Node new];
    B7Node *child = [B7Node new];
    root.next = child;
    child.next = root;
    error = nil;
    NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:root requiringSecureCoding:YES error:&error];
    B7Node *decoded = archive ? [NSKeyedUnarchiver unarchivedObjectOfClass:[B7Node class]
        fromData:archive error:&error] : nil;
    BOOL cycle = decoded && decoded.next && decoded.next != decoded && decoded.next.next == decoded;
    root.next = nil;
    child.next = nil;
    if (cycle) decoded.next.next = nil;
    decoded.next = nil;

    error = nil;
    id rejected = archive ? [NSKeyedUnarchiver unarchivedObjectOfClass:[NSNumber class]
        fromData:archive error:&error] : nil;
    BOOL secureError = rejected == nil && error != nil;
    BOOL ok = jsonOK && plistOK && cycle && secureError;
    return B7Check(@"D8", ok, [NSString stringWithFormat:@"json=%d plist=%d cycle=%d secureError=%d rejectedNil=%d error=%d",
                               jsonOK, plistOK, cycle, secureError, rejected == nil, error != nil]);
}

static NSString *B7DocumentsPath(void) {
    NSArray<NSURL *> *urls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
        inDomains:NSUserDomainMask];
    return urls.firstObject.path;
}

static BOOL B7WritePersistenceCount(NSInteger count) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:count forKey:@"b7.counter"];
    BOOL defaultsSaved = [defaults synchronize];
    NSString *path = [B7DocumentsPath() stringByAppendingPathComponent:@"b7-counter.txt"];
    NSData *data = [[NSString stringWithFormat:@"%ld", (long)count] dataUsingEncoding:NSUTF8StringEncoding];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error = nil;
    if ([manager fileExistsAtPath:path]) {
        [manager removeItemAtPath:path error:&error];
    }
    BOOL fileSaved = [manager createFileAtPath:path contents:data attributes:nil];
    return defaultsSaved && fileSaved;
}

static BOOL B7TestPersistence(NSInteger *countOut) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger defaultsCount = [defaults integerForKey:@"b7.counter"];
    NSString *path = [B7DocumentsPath() stringByAppendingPathComponent:@"b7-counter.txt"];
    NSError *error = nil;
    NSString *fileCount = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    BOOL fileMatches = fileCount ? [fileCount integerValue] == defaultsCount : defaultsCount == 0;
    *countOut = defaultsCount;
    return B7Check(@"D11_D12", fileMatches,
                   [NSString stringWithFormat:@"defaults=%ld file=%@", (long)defaultsCount, fileCount ?: @"<absent>"]);
}

static BOOL B7TestDates(void) {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:1600000000.25];
    NSDate *equal = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:621692800.25];
    NSDate *earlier = [date dateByAddingTimeInterval:-1.5];
    BOOL epoch = date.timeIntervalSince1970 == 1600000000.25 &&
        date.timeIntervalSinceReferenceDate == 621692800.25;
    BOOL arithmetic = [date timeIntervalSinceDate:earlier] == 1.5 &&
        [earlier compare:date] == NSOrderedAscending && [date compare:earlier] == NSOrderedDescending &&
        [date isEqualToDate:equal] && [date earlierDate:earlier] == earlier && [date laterDate:earlier] == date;

    NSString *path = [B7DocumentsPath() stringByAppendingPathComponent:@"b7-date.txt"];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSDate *beforeWrite = [NSDate dateWithTimeIntervalSinceNow:-2.0];
    BOOL wrote = [manager createFileAtPath:path contents:[@"date" dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    NSDictionary *attributes = [manager attributesOfItemAtPath:path error:nil];
    NSDate *modified = attributes[NSFileModificationDate];
    NSDate *afterWrite = [NSDate dateWithTimeIntervalSinceNow:2.0];
    BOOL dateObject = [modified isKindOfClass:[NSDate class]];
    BOOL dateRange = dateObject &&
        [modified compare:beforeWrite] != NSOrderedAscending &&
        [modified compare:afterWrite] != NSOrderedDescending;
    NSTimeInterval epochDelta = modified.timeIntervalSinceReferenceDate -
        (modified.timeIntervalSince1970 - 978307200.0);
    BOOL epochConsistent = epochDelta > -0.000001 && epochDelta < 0.000001;
    BOOL fileDate = wrote && dateObject && dateRange && epochConsistent;

    NSError *error = nil;
    NSData *plist = [NSPropertyListSerialization dataWithPropertyList:@[date] format:NSPropertyListBinaryFormat_v1_0
                                                            options:0 error:&error];
    NSArray *decoded = plist ? [NSPropertyListSerialization propertyListWithData:plist options:0 format:NULL error:&error] : nil;
    BOOL roundTrip = error == nil && [decoded.firstObject isEqualToDate:date];
    return B7Check(@"D7", epoch && arithmetic && fileDate && roundTrip,
                   [NSString stringWithFormat:@"epoch=%d arithmetic=%d file=%d wrote=%d date=%d range=%d epochDelta=%.9f plist=%d",
                    epoch, arithmetic, fileDate, wrote, dateObject, dateRange, epochDelta, roundTrip]);
}

static int B7SQLiteCountCallback(void *context, int columns, char **values, char **names) {
    (void)names;
    if (columns > 0 && values[0]) {
        const char *value = values[0];
        int count = 0;
        if (*value == '\0') return 1;
        for (; *value != '\0'; value++) {
            if (*value < '0' || *value > '9') return 1;
            count = count * 10 + (*value - '0');
        }
        *(int *)context = count;
    }
    return 0;
}

static BOOL B7TestSQLite(NSInteger *rowCountOut) {
    NSString *path = [B7DocumentsPath() stringByAppendingPathComponent:@"b7.sqlite"];
    sqlite3 *db = NULL;
    if (sqlite3_open(path.UTF8String, &db) != SQLITE_OK || !db) {
        if (db) sqlite3_close(db);
        *rowCountOut = -1;
        return B7Check(@"I3", NO, @"open failed");
    }
    BOOL ok = sqlite3_exec(db,
        "CREATE TABLE IF NOT EXISTS records (id INTEGER PRIMARY KEY, text TEXT NOT NULL);"
        "DELETE FROM records WHERE id IN (2, 3);", NULL, NULL, NULL) == SQLITE_OK;

    sqlite3_stmt *insert = NULL;
    const char sql[] = "INSERT OR IGNORE INTO records (id, text) VALUES (1, ?1)";
    ok &= sqlite3_prepare_v2(db, sql, -1, &insert, NULL) == SQLITE_OK;
    const char embeddedNul[] = {'a', '\0', 'b'};
    if (insert) {
        ok &= sqlite3_bind_text(insert, 1, embeddedNul, 3, SQLITE_TRANSIENT) == SQLITE_OK;
        ok &= sqlite3_step(insert) == SQLITE_DONE;
        sqlite3_finalize(insert);
    }

    sqlite3_stmt *query = NULL;
    ok &= sqlite3_prepare_v2(db, "SELECT hex(text) FROM records WHERE id = 1", -1, &query, NULL) == SQLITE_OK;
    if (query) {
        int step = sqlite3_step(query);
        const unsigned char *hex = sqlite3_column_text(query, 0);
        ok &= step == SQLITE_ROW && hex && strcmp((const char *)hex, "610062") == 0;
        sqlite3_finalize(query);
    }
    ok &= sqlite3_exec(db, "BEGIN; INSERT INTO records (id, text) VALUES (2, 'rollback'); ROLLBACK;",
                       NULL, NULL, NULL) == SQLITE_OK;
    int afterRollback = 0;
    ok &= sqlite3_exec(db, "SELECT COUNT(*) FROM records", B7SQLiteCountCallback, &afterRollback, NULL) == SQLITE_OK;
    ok &= afterRollback == 1;
    ok &= sqlite3_exec(db, "BEGIN; INSERT INTO records (id, text) VALUES (3, 'committed'); COMMIT;",
                       NULL, NULL, NULL) == SQLITE_OK;
    int count = 0;
    ok &= sqlite3_exec(db, "SELECT COUNT(*) FROM records", B7SQLiteCountCallback, &count, NULL) == SQLITE_OK;
    ok &= sqlite3_close(db) == SQLITE_OK;
    *rowCountOut = count;
    return B7Check(@"I3", ok && count == 2,
                   [NSString stringWithFormat:@"rows=%d rollbackRows=%d", count, afterRollback]);
}

static NSData *B7RunDataTask(NSURLSession *session, NSURLRequest *request,
                             NSHTTPURLResponse **responseOut, NSError **errorOut) {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSData *received = nil;
    __block NSHTTPURLResponse *response = nil;
    __block NSError *failure = nil;
    void (^completion)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *rawResponse, NSError *error) {
        received = data;
        response = [rawResponse isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)rawResponse : nil;
        failure = error;
        dispatch_semaphore_signal(semaphore);
    };
    BOOL customRequest = request.HTTPBody != nil ||
        (request.HTTPMethod != nil && ![request.HTTPMethod isEqualToString:@"GET"]);
    NSURLSessionDataTask *task = customRequest ? [session dataTaskWithRequest:request completionHandler:completion] :
        [session dataTaskWithURL:request.URL completionHandler:completion];
    [task resume];
    BOOL timedOut = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC)) != 0;
    if (responseOut) *responseOut = response;
    if (errorOut) *errorOut = timedOut ? [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil] : failure;
    return timedOut ? nil : received;
}

static NSData *B7RunDownloadTask(NSURLSession *session, NSURL *url, NSHTTPURLResponse **responseOut, NSError **errorOut) {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSData *received = nil;
    __block NSHTTPURLResponse *response = nil;
    __block NSError *failure = nil;
    [[session downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *rawResponse, NSError *error) {
        if (location) received = [NSData dataWithContentsOfURL:location];
        response = [rawResponse isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)rawResponse : nil;
        failure = error;
        dispatch_semaphore_signal(semaphore);
    }] resume];
    BOOL timedOut = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC)) != 0;
    if (responseOut) *responseOut = response;
    if (errorOut) *errorOut = timedOut ? [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil] : failure;
    return timedOut ? nil : received;
}

static BOOL B7TestNetworking(void) {
    NSDictionary *environment = NSProcessInfo.processInfo.environment;
    NSString *base = environment[@"B7_NETWORK_BASE_URL"];
    if (base.length == 0) {
        B7Write(@"I1=SKIP set B7_NETWORK_BASE_URL to run network requests");
        return YES;
    }
    NSURLComponents *components = [NSURLComponents componentsWithString:base];
    components.queryItems = @[[NSURLQueryItem queryItemWithName:@"city" value:@"München"]];
    BOOL queryOK = [components.percentEncodedQuery containsString:@"%C3%BC"] &&
        [components.queryItems.firstObject.value isEqualToString:@"München"];

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.timeoutIntervalForRequest = 10;
    NSOperationQueue *queue = [NSOperationQueue new];
    queue.maxConcurrentOperationCount = 1;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:queue];
    NSError *error = nil;
    NSHTTPURLResponse *response = nil;
    NSURL *jsonURL = [NSURL URLWithString:[base stringByAppendingString:@"/json"]];
    NSData *jsonData = B7RunDataTask(session, [NSURLRequest requestWithURL:jsonURL], &response, &error);
    NSDictionary *json = jsonData ? [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil] : nil;
    BOOL localJSON = response.statusCode == 200 && [json[@"ok"] boolValue];

    NSMutableURLRequest *post = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[base stringByAppendingString:@"/echo"]]];
    post.HTTPMethod = @"POST";
    post.HTTPBody = [@"fixture-post" dataUsingEncoding:NSUTF8StringEncoding];
    error = nil;
    response = nil;
    NSData *posted = B7RunDataTask(session, post, &response, &error);
    BOOL postOK = response.statusCode == 200 && [posted isEqual:[@"fixture-post" dataUsingEncoding:NSUTF8StringEncoding]];

    error = nil;
    response = nil;
    NSData *downloaded = B7RunDownloadTask(session, [NSURL URLWithString:[base stringByAppendingString:@"/download"]], &response, &error);
    BOOL downloadOK = response.statusCode == 200 && [downloaded isEqual:[@"fixture-download" dataUsingEncoding:NSUTF8StringEncoding]];

    error = nil;
    response = nil;
    (void)B7RunDataTask(session, [NSURLRequest requestWithURL:[NSURL URLWithString:[base stringByAppendingString:@"/not-found"]]], &response, &error);
    BOOL notFoundOK = response.statusCode == 404 && error == nil;

    error = nil;
    response = nil;
    (void)B7RunDataTask(session, [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://127.0.0.1:1/unreachable"]], &response, &error);
    BOOL unreachableOK = [error.domain isEqualToString:NSURLErrorDomain] && error.code != 0;
    NSInteger unreachableCode = error.code;

    NSString *publicURL = environment[@"B7_PUBLIC_JSON_URL"] ?: @"https://jsonplaceholder.typicode.com/todos/1";
    error = nil;
    response = nil;
    NSData *publicData = B7RunDataTask(session, [NSURLRequest requestWithURL:[NSURL URLWithString:publicURL]], &response, &error);
    NSDictionary *publicJSON = publicData ? [NSJSONSerialization JSONObjectWithData:publicData options:0 error:nil] : nil;
    BOOL publicOK = response.statusCode == 200 && [publicJSON isKindOfClass:[NSDictionary class]] && publicJSON[@"id"] != nil;
    [session invalidateAndCancel];

    BOOL ok = queryOK && localJSON && postOK && downloadOK && notFoundOK && unreachableOK && publicOK;
    return B7Check(@"I1", ok, [NSString stringWithFormat:@"query=%d local=%d post=%d download=%d 404=%d unreachable=%d/%ld public=%d",
                               queryOK, localJSON, postOK, downloadOK, notFoundOK, unreachableOK,
                               (long)unreachableCode, publicOK]);
}

static CFComparisonResult B7CompareCFNumbers(const void *left, const void *right, void *context) {
    (void)context;
    int32_t a = 0, b = 0;
    CFNumberGetValue((CFNumberRef)left, kCFNumberSInt32Type, &a);
    CFNumberGetValue((CFNumberRef)right, kCFNumberSInt32Type, &b);
    return a < b ? kCFCompareLessThan : (a > b ? kCFCompareGreaterThan : kCFCompareEqualTo);
}

static BOOL B7TestCoreFoundation(void) {
    CFStringRef unicode = CFStringCreateWithCString(kCFAllocatorDefault, "\x41\xF0\x9F\x98\x80\x42", kCFStringEncodingUTF8);
    BOOL unicodeOK = unicode && CFStringGetLength(unicode) == 4;

    const UniChar source[] = { 'A', 0x20AC, 'B' };
    CFStringRef lossy = CFStringCreateWithCharacters(kCFAllocatorDefault, source, 3);
    UInt8 bytes[8] = {0};
    CFIndex used = 0;
    CFIndex converted = CFStringGetBytes(lossy, CFRangeMake(0, 3), kCFStringEncodingISOLatin1,
        '?', false, bytes, sizeof(bytes), &used);
    BOOL bytesOK = converted == 3 && used == 3 && memcmp(bytes, "A?B", 3) == 0;

    CFMutableDictionaryRef dictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
        &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionaryAddValue(dictionary, CFSTR("name"), CFSTR("Ada"));
    CFDictionaryAddValue(dictionary, CFSTR("name"), CFSTR("ignored"));
    CFDictionaryReplaceValue(dictionary, CFSTR("name"), CFSTR("Grace"));
    BOOL dictionaryOK = CFDictionaryGetCount(dictionary) == 1 &&
        CFEqual(CFDictionaryGetValue(dictionary, CFSTR("name")), CFSTR("Grace"));

    int32_t three = 3, one = 1, two = 2;
    CFNumberRef numbers[] = {
        CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &three),
        CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &one),
        CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &two)
    };
    CFMutableArrayRef array = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
    for (CFIndex index = 0; index < 3; index++) CFArrayAppendValue(array, numbers[index]);
    CFArraySortValues(array, CFRangeMake(0, 3), B7CompareCFNumbers, NULL);
    int32_t first = 0, last = 0;
    CFNumberGetValue((CFNumberRef)CFArrayGetValueAtIndex(array, 0), kCFNumberSInt32Type, &first);
    CFNumberGetValue((CFNumberRef)CFArrayGetValueAtIndex(array, 2), kCFNumberSInt32Type, &last);
    BOOL sortOK = first == 1 && last == 3;

    // Use an in-range fractional conversion; overflow output is not a portable CF contract.
    double fractional = 3.75;
    CFNumberRef number = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloat64Type, &fractional);
    int32_t truncated = 0;
    BOOL exact = CFNumberGetValue(number, kCFNumberSInt32Type, &truncated);
    BOOL lossyNumberOK = !exact && truncated == 3;
    BOOL booleanTypeOK = CFGetTypeID(kCFBooleanTrue) == CFBooleanGetTypeID();

    CFLocaleRef turkish = CFLocaleCreate(kCFAllocatorDefault, CFSTR("tr_TR"));
    CFLocaleRef english = CFLocaleCreate(kCFAllocatorDefault, CFSTR("en_US"));
    CFRange localeRange = CFRangeMake(-1, 0);
    BOOL localeOK = CFStringCompareWithOptionsAndLocale(CFSTR("I"), CFSTR("ı"), CFRangeMake(0, 1),
        kCFCompareCaseInsensitive, turkish) == kCFCompareEqualTo &&
        CFStringCompareWithOptionsAndLocale(CFSTR("I"), CFSTR("ı"), CFRangeMake(0, 1),
        kCFCompareCaseInsensitive, english) != kCFCompareEqualTo &&
        CFStringFindWithOptionsAndLocale(CFSTR("😀I"), CFSTR("ı"), CFRangeMake(2, 1),
        kCFCompareCaseInsensitive, turkish, &localeRange) && localeRange.location == 2 && localeRange.length == 1;

    BOOL ok = unicodeOK && bytesOK && dictionaryOK && sortOK && lossyNumberOK && booleanTypeOK && localeOK;
    NSString *detail = [NSString stringWithFormat:@"unicode=%ld bytes=%ld/%ld sort=%d number=%d bool=%d locale=%d",
        unicode ? (long)CFStringGetLength(unicode) : -1, (long)converted, (long)used,
        sortOK, lossyNumberOK, booleanTypeOK, localeOK];
    if (turkish) CFRelease(turkish);
    if (english) CFRelease(english);
    if (unicode) CFRelease(unicode);
    if (lossy) CFRelease(lossy);
    if (dictionary) CFRelease(dictionary);
    if (array) CFRelease(array);
    if (number) CFRelease(number);
    for (CFIndex index = 0; index < 3; index++) if (numbers[index]) CFRelease(numbers[index]);
    return B7Check(@"D13", ok, detail);
}

static BOOL B7RunSelectedGroups(NSInteger *sqliteRowsOut) {
    NSDictionary *environment = NSProcessInfo.processInfo.environment;
    NSString *selection = environment[@"B7_GROUPS"];
    NSArray<NSString *> *groups = selection.length ? [selection componentsSeparatedByString:@","] :
        @[@"D2", @"D3", @"D4", @"D5", @"D7", @"D8", @"D11_D12", @"I1", @"I3", @"D13"];
    BOOL allOK = YES;
    for (NSString *group in groups) {
        @try {
            BOOL ok = NO;
            if ([group isEqualToString:@"D2"]) ok = B7TestMemoryManagement();
            else if ([group isEqualToString:@"D3"]) ok = B7TestKeyValueAndObservation();
            else if ([group isEqualToString:@"D4"]) ok = B7TestStrings();
            else if ([group isEqualToString:@"D5"]) ok = B7TestCollections();
            else if ([group isEqualToString:@"D7"]) ok = B7TestDates();
            else if ([group isEqualToString:@"D8"]) ok = B7TestSerialization();
            else if ([group isEqualToString:@"D11_D12"]) {
                NSInteger count = 0;
                ok = B7TestPersistence(&count);
            } else if ([group isEqualToString:@"I1"]) ok = B7TestNetworking();
            else if ([group isEqualToString:@"I3"]) ok = B7TestSQLite(sqliteRowsOut);
            else if ([group isEqualToString:@"D13"]) ok = B7TestCoreFoundation();
            else {
                NSString *line = [NSString stringWithFormat:@"%@=FAIL unknown group", group];
                B7Write(line);
                [B7FailureDetails addObject:line];
                allOK = NO;
                continue;
            }
            allOK &= ok;
        } @catch (NSException *exception) {
            NSString *line = [NSString stringWithFormat:@"%@=FAIL exception=%@:%@", group, exception.name, exception.reason];
            B7Write(line);
            [B7FailureDetails addObject:line];
            allOK = NO;
        }
    }
    return allOK;
}

@interface ViewController ()
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *counterLabel;
@property (nonatomic, strong) UILabel *sqliteLabel;
@property (nonatomic) NSInteger sqliteRows;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;

    UIStackView *content = [[UIStackView alloc] init];
    content.axis = UILayoutConstraintAxisVertical;
    content.alignment = UIStackViewAlignmentFill;
    content.spacing = 16;
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:content];
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [content.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:24],
        [content.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-24],
        [content.topAnchor constraintEqualToAnchor:safe.topAnchor constant:32]
    ]];

    UILabel *title = [[UILabel alloc] init];
    title.text = @"B7 Framework Regression Suite";
    title.font = [UIFont systemFontOfSize:25 weight:UIFontWeightBold];
    title.accessibilityIdentifier = @"b7.title";
    [content addArrangedSubview:title];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.text = @"B7_RUNNING";
    self.statusLabel.accessibilityIdentifier = @"b7.status";
    [content addArrangedSubview:self.statusLabel];

    NSInteger counter = [[NSUserDefaults standardUserDefaults] integerForKey:@"b7.counter"];
    self.counterLabel = [[UILabel alloc] init];
    self.counterLabel.text = [NSString stringWithFormat:@"Count: %ld", (long)counter];
    self.counterLabel.accessibilityIdentifier = @"persistence.counter";
    [content addArrangedSubview:self.counterLabel];

    UIButton *save = [UIButton buttonWithType:UIButtonTypeSystem];
    [save setTitle:@"Save count" forState:UIControlStateNormal];
    save.accessibilityIdentifier = @"persistence.save";
    [save addTarget:self action:@selector(saveCount) forControlEvents:UIControlEventTouchUpInside];
    [content addArrangedSubview:save];

    self.sqliteLabel = [[UILabel alloc] init];
    self.sqliteLabel.accessibilityIdentifier = @"persistence.sqlite";
    [content addArrangedSubview:self.sqliteLabel];

    self.sqliteRows = 0;
    B7FailureDetails = [NSMutableArray array];
    BOOL ok = B7RunSelectedGroups(&_sqliteRows);
    self.statusLabel.text = ok ? @"B7_OK" :
        [NSString stringWithFormat:@"B7_FAIL: %@", [B7FailureDetails componentsJoinedByString:@" | "]];
    self.sqliteLabel.text = [NSString stringWithFormat:@"Rows: %ld", (long)self.sqliteRows];
    B7Write(ok ? @"B7_OK" : @"B7_FAIL");
}

- (void)saveCount {
    NSInteger next = [[NSUserDefaults standardUserDefaults] integerForKey:@"b7.counter"] + 1;
    BOOL saved = B7WritePersistenceCount(next);
    self.counterLabel.text = [NSString stringWithFormat:@"Count: %ld", (long)next];
    B7Write([NSString stringWithFormat:@"D11_D12_SAVE=%@ count=%ld", saved ? @"ok" : @"FAIL", (long)next]);
}

@end
