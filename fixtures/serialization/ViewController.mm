#import "ViewController.h"
#include <stdio.h>

static NSInteger noteInitializations, legacyInitializations;

@interface ArchiveNote : NSObject <NSSecureCoding>
@property(nonatomic, copy) NSString *text;
@property(nonatomic) NSInteger number;
@end
@implementation ArchiveNote
+ (BOOL)supportsSecureCoding { return YES; }
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.text forKey:@"text"];
    [coder encodeInteger:self.number forKey:@"number"];
}
- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        ++noteInitializations;
        self.text = [coder decodeObjectOfClass:NSString.class forKey:@"text"];
        self.number = [coder decodeIntegerForKey:@"number"];
    }
    return self;
}
@end

@interface LegacyNote : NSObject <NSCoding>
@property(nonatomic) NSInteger number;
@end
@implementation LegacyNote
- (void)encodeWithCoder:(NSCoder *)coder { [coder encodeInteger:self.number forKey:@"number"]; }
- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) { ++legacyInitializations; self.number = [coder decodeIntegerForKey:@"number"]; }
    return self;
}
@end

static void archiveLine(const char *name, NSData *data) {
    printf("SER_ARCHIVE_HEX name=%s bytes=%lu hex=", name, (unsigned long)data.length);
    const unsigned char *bytes = (const unsigned char *)data.bytes;
    for (NSUInteger i = 0; i < data.length; ++i) printf("%02x", bytes[i]);
    printf("\n");
}

static BOOL referenceChecks(void) {
    BOOL ok = YES;
    NSError *error = nil;
    NSArray *values = @[@"Grüße", @7, @YES, @{@"name": @"value"}];
    NSData *json = [NSJSONSerialization dataWithJSONObject:values options:NSJSONWritingSortedKeys error:&error];
    id jsonValue = [NSJSONSerialization JSONObjectWithData:json options:0 error:&error];
    BOOL jsonOK = [jsonValue isEqual:values] && !error;
    printf("SER_JSON equal=%d count=%lu error=%ld\n", jsonOK, (unsigned long)[jsonValue count], (long)error.code);
    ok &= jsonOK;
    for (NSNumber *formatNumber in @[@(NSPropertyListXMLFormat_v1_0), @(NSPropertyListBinaryFormat_v1_0)]) {
        NSPropertyListFormat format = (NSPropertyListFormat)formatNumber.integerValue, readFormat = (NSPropertyListFormat)0;
        error = nil;
        NSData *plist = [NSPropertyListSerialization dataWithPropertyList:values format:format options:0 error:&error];
        id read = [NSPropertyListSerialization propertyListWithData:plist options:NSPropertyListImmutable format:&readFormat error:&error];
        BOOL equal = [read isEqual:values] && readFormat == format && !error;
        printf("SER_PLIST format=%lu read=%lu equal=%d error=%ld\n", (unsigned long)format, (unsigned long)readFormat, equal, (long)error.code);
        ok &= equal;
    }

    ArchiveNote *note = [ArchiveNote new]; note.text = @"Grüße"; note.number = 17;
    error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:@[note, note] requiringSecureCoding:YES error:&error];
    archiveLine("secure-array", data);
    noteInitializations = 0;
    NSArray *read = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithObjects:NSArray.class, ArchiveNote.class, NSString.class, nil]
                                                     fromData:data error:&error];
    ArchiveNote *first = read.count ? read[0] : nil;
    BOOL secureOK = read.count == 2 && first == read[1] && noteInitializations == 1 && first.number == 17 && [first.text isEqualToString:@"Grüße"] && !error;
    printf("SER_SECURE count=%lu same=%d init=%ld number=%ld text=%d error=%ld\n", (unsigned long)read.count,
           read.count == 2 && first == read[1], (long)noteInitializations, (long)first.number,
           [first.text isEqualToString:@"Grüße"], (long)error.code);
    ok &= secureOK;

    LegacyNote *legacy = [LegacyNote new]; legacy.number = 23;
    NSData *legacyData = [NSKeyedArchiver archivedDataWithRootObject:legacy requiringSecureCoding:NO error:&error];
    archiveLine("legacy-note", legacyData);
    legacyInitializations = 0;
    LegacyNote *legacyRead = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:legacyData error:&error];
    BOOL legacyOK = legacyRead.number == 23 && legacyInitializations == 1 && !error;
    printf("SER_LEGACY number=%ld init=%ld error=%ld\n", (long)legacyRead.number, (long)legacyInitializations, (long)error.code);
    ok &= legacyOK;

    for (NSNumber *mode in @[@0, @1, @2]) {
        error = nil; legacyInitializations = 0;
        id bad = nil; NSString *exceptionName = @"none";
        @try {
            if (mode.integerValue == 0) {
                bad = [NSKeyedUnarchiver unarchivedObjectOfClass:LegacyNote.class fromData:legacyData error:&error];
            } else if (mode.integerValue == 1) {
                bad = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithObject:LegacyNote.class] fromData:legacyData error:&error];
            } else {
                NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc] initForReadingFromData:legacyData error:&error];
                bad = [decoder decodeObjectOfClass:LegacyNote.class forKey:NSKeyedArchiveRootObjectKey];
                error = decoder.error;
                [decoder finishDecoding];
            }
        } @catch (NSException *exception) { exceptionName = exception.name; }
        BOOL refused = !bad && legacyInitializations == 0 && (error || ![exceptionName isEqualToString:@"none"]);
        printf("SER_REFUSE mode=%ld nil=%d init=%ld domain=%s code=%ld exception=%s\n", (long)mode.integerValue,
               bad == nil, (long)legacyInitializations, error ? error.domain.UTF8String : "none", (long)error.code, exceptionName.UTF8String);
        ok &= refused;
    }

    error = nil;
    NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:&error];
    BOOL raised = NO;
    @try { decoder.requiresSecureCoding = NO; } @catch (NSException *exception) { raised = YES; }
    printf("SER_POLICY disableRaised=%d stillSecure=%d\n", raised, decoder.requiresSecureCoding);
    ok &= raised && decoder.requiresSecureCoding;
    [decoder finishDecoding];

    NSKeyedArchiver *writer = [[NSKeyedArchiver alloc] initRequiringSecureCoding:NO];
    [writer encodeObject:legacy forKey:@"bad"];
    [writer encodeObject:@"readable" forKey:@"after"];
    [writer finishEncoding];
    archiveLine("failure-policy", writer.encodedData);
    decoder = [[NSKeyedUnarchiver alloc] initForReadingFromData:writer.encodedData error:&error];
    id bad = [decoder decodeObjectOfClass:LegacyNote.class forKey:@"bad"];
    id after = [decoder decodeObjectOfClass:NSString.class forKey:@"after"];
    printf("SER_POLICY badNil=%d error=%ld afterNil=%d\n", bad == nil, (long)decoder.error.code, after == nil);
    ok &= !bad && decoder.error && !after;
    [decoder finishDecoding];
    printf("%s\n", ok ? "SER_OK" : "SER_FAIL");
    return ok;
}

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    BOOL ok = referenceChecks();
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, 350, 70)];
    label.text = ok ? @"SERIALIZATION_OK" : @"SERIALIZATION_FAIL";
    label.accessibilityIdentifier = @"serialization.status";
    [self.view addSubview:label];
}
@end
