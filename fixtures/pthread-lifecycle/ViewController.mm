#import "ViewController.h"
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

// Reference probe: expected values are not measured until the native run.
static int tlvLog[8], tlvCount, keyLog[8], keyCount, deletedCalls;
static bool sameThread, clearedBeforeKeyCall;
static pthread_t workerThread;
static pthread_key_t key, deletedKey;
struct LocalObject;
static LocalObject &third();
struct LocalObject {
    int identifier;
    explicit LocalObject(int value) : identifier(value) {}
    ~LocalObject() {
        sameThread = sameThread && pthread_equal(pthread_self(), workerThread);
        if (tlvCount < 8) tlvLog[tlvCount++] = identifier;
        if (identifier == 2) (void)third().identifier;
    }
};
// Separate function-local values avoid a shared translation-unit initializer.
static LocalObject &first() { static thread_local LocalObject value(1); return value; }
static LocalObject &second() { static thread_local LocalObject value(2); return value; }
static LocalObject &third() { static thread_local LocalObject value(3); return value; }
static void keyDestructor(void *value) {
    sameThread = sameThread && pthread_equal(pthread_self(), workerThread);
    clearedBeforeKeyCall = clearedBeforeKeyCall && pthread_getspecific(key) == nullptr;
    intptr_t number = (intptr_t)value;
    if (keyCount < 8) keyLog[keyCount++] = (int)number;
    if (number == 7) (void)pthread_setspecific(key, (void *)(intptr_t)8);
}
static void deletedDestructor(void *) { ++deletedCalls; }
static void *worker(void *mode) {
    workerThread = pthread_self();
    (void)first().identifier;
    (void)second().identifier;
    if (pthread_setspecific(key, (void *)(intptr_t)7) != 0) return (void *)(intptr_t)1;
    if (pthread_setspecific(deletedKey, (void *)(intptr_t)9) != 0) return (void *)(intptr_t)2;
    if (pthread_key_delete(deletedKey) != 0) return (void *)(intptr_t)3;
    if ((intptr_t)mode != 0) pthread_exit((void *)(intptr_t)0x2345);
    return (void *)(intptr_t)0x1234;
}
static bool runCase(int mode) {
    tlvCount = keyCount = deletedCalls = 0;
    sameThread = clearedBeforeKeyCall = true;
    memset(tlvLog, 0, sizeof(tlvLog));
    memset(keyLog, 0, sizeof(keyLog));
    int createKey = pthread_key_create(&key, keyDestructor);
    int createDeleted = pthread_key_create(&deletedKey, deletedDestructor);
    if (createKey != 0 || createDeleted != 0) {
        if (createKey == 0) (void)pthread_key_delete(key);
        if (createDeleted == 0) (void)pthread_key_delete(deletedKey);
        return false;
    }
    pthread_t tid;
    void *result = nullptr;
    int created = pthread_create(&tid, nullptr, worker, (void *)(intptr_t)mode);
    int joined = created == 0 ? pthread_join(tid, &result) : -1;
    bool mainIsolated = pthread_getspecific(key) == nullptr;
    bool expected = created == 0 && joined == 0
        && (intptr_t)result == (mode ? 0x2345 : 0x1234)
        && tlvCount == 3 && tlvLog[0] == 2 && tlvLog[1] == 3 && tlvLog[2] == 1
        && keyCount == 2 && keyLog[0] == 7 && keyLog[1] == 8
        && deletedCalls == 0 && sameThread && clearedBeforeKeyCall && mainIsolated;
    char line[256];
    int n = snprintf(line, sizeof(line),
        "C1_END mode=%d create=%d join=%d result=%lx tlv=%d:%d,%d,%d key=%d:%d,%d deleted=%d same=%d cleared=%d main=%d ok=%d\n",
        mode, created, joined, (unsigned long)(uintptr_t)result,
        tlvCount, tlvLog[0], tlvLog[1], tlvLog[2], keyCount, keyLog[0], keyLog[1],
        deletedCalls, sameThread, clearedBeforeKeyCall, mainIsolated, expected);
    if (n > 0) (void)write(STDOUT_FILENO, line, (size_t)n < sizeof(line) ? (size_t)n : sizeof(line) - 1);
    (void)pthread_key_delete(key);
    if (created != 0) (void)pthread_key_delete(deletedKey);
    return expected;
}
@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(20, 160, 350, 80)];
    status.accessibilityIdentifier = @"pthreadlifecycle.status";
    status.numberOfLines = 0;
    bool returned = runCase(0);
    bool exited = runCase(1);
    status.text = returned && exited ? @"PTHREAD_LIFECYCLE_OK" : @"PTHREAD_LIFECYCLE_FAIL";
    [self.view addSubview:status];
    const char *end = returned && exited ? "C1_END_OK\n" : "C1_END_FAIL\n";
    (void)write(STDOUT_FILENO, end, strlen(end));
}
@end
