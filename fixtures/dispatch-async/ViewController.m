#import "ViewController.h"

#import <dispatch/dispatch.h>
#import <pthread.h>
#import <stdatomic.h>
#import <string.h>
#import <unistd.h>

static int sSerialValues[3];
static _Atomic int sSerialIndex;
static _Atomic int sBarrierPreCount;
static _Atomic int sBarrierPassed;
static _Atomic int sBarrierAfterValid;
static _Atomic int sBarrierAfterCount;
static _Atomic int sMainQueueWasMain;
static _Atomic int sGroupWorkFinished;
static _Atomic int sGroupNotifySawWork;
static _Atomic int sAfterFired;
static _Atomic int sTimerFired;
static dispatch_once_t sOnceToken;
static _Atomic int sOnceRuns;
static _Atomic int sOnceValue;
static _Atomic int sOnceObservers;

static void write_line(const char *line) {
    size_t remaining = strlen(line);
    const char *cursor = line;
    while (remaining > 0) {
        ssize_t written = write(STDOUT_FILENO, cursor, remaining);
        if (written <= 0) {
            break;
        }
        cursor += written;
        remaining -= (size_t)written;
    }
    (void)write(STDOUT_FILENO, "\n", 1);
}

static BOOL wait_for_signal(dispatch_semaphore_t semaphore) {
    const int64_t deadline = dispatch_time(DISPATCH_TIME_NOW, 5LL * 1000 * 1000 * 1000);
    return dispatch_semaphore_wait(semaphore, deadline) == 0;
}

static void *once_worker(void *unused) {
    (void)unused;
    dispatch_once(&sOnceToken, ^{
        atomic_fetch_add(&sOnceRuns, 1);
        atomic_store(&sOnceValue, 42);
    });
    if (atomic_load(&sOnceValue) == 42) {
        atomic_fetch_add(&sOnceObservers, 1);
    }
    return NULL;
}

static BOOL run_dispatch_scenario(void) {
    BOOL passed = YES;
    dispatch_queue_t global = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    dispatch_queue_t serial = dispatch_queue_create("org.ipahle.fixture.dispatch.serial", DISPATCH_QUEUE_SERIAL);
    dispatch_group_t serialGroup = dispatch_group_create();
    atomic_store(&sSerialIndex, 0);
    for (int value = 1; value <= 3; value++) {
        dispatch_group_async(serialGroup, serial, ^{
            int index = atomic_fetch_add(&sSerialIndex, 1);
            if (index < 3) {
                sSerialValues[index] = value;
            }
        });
    }
    BOOL serialFinished = dispatch_group_wait(
        serialGroup, dispatch_time(DISPATCH_TIME_NOW, 5LL * 1000 * 1000 * 1000)
    ) == 0;
    BOOL serialFIFO = serialFinished
        && atomic_load(&sSerialIndex) == 3
        && sSerialValues[0] == 1
        && sSerialValues[1] == 2
        && sSerialValues[2] == 3;
    write_line(serialFIFO ? "serial FIFO: OK" : "serial FIFO: FAIL");
    passed = passed && serialFIFO;

    pthread_t syncCaller = pthread_self();
    __block int syncRanOnCaller = 0;
    dispatch_sync(serial, ^{
        syncRanOnCaller = pthread_equal(syncCaller, pthread_self()) != 0;
    });
    write_line(syncRanOnCaller ? "dispatch_sync caller: OK" : "dispatch_sync caller: FAIL");
    passed = passed && syncRanOnCaller;

    dispatch_queue_t concurrent = dispatch_queue_create(
        "org.ipahle.fixture.dispatch.concurrent", DISPATCH_QUEUE_CONCURRENT
    );
    dispatch_group_t beforeBarrier = dispatch_group_create();
    atomic_store(&sBarrierPreCount, 0);
    atomic_store(&sBarrierPassed, 0);
    atomic_store(&sBarrierAfterValid, 1);
    atomic_store(&sBarrierAfterCount, 0);
    for (int index = 0; index < 3; index++) {
        dispatch_group_async(beforeBarrier, concurrent, ^{
            atomic_fetch_add(&sBarrierPreCount, 1);
        });
    }
    dispatch_barrier_async(concurrent, ^{
        atomic_store(&sBarrierPassed, atomic_load(&sBarrierPreCount) == 3);
    });
    dispatch_group_t afterBarrier = dispatch_group_create();
    for (int index = 0; index < 2; index++) {
        dispatch_group_async(afterBarrier, concurrent, ^{
            if (!atomic_load(&sBarrierPassed)) {
                atomic_store(&sBarrierAfterValid, 0);
            }
            atomic_fetch_add(&sBarrierAfterCount, 1);
        });
    }
    BOOL barrierFinished = dispatch_group_wait(
        afterBarrier, dispatch_time(DISPATCH_TIME_NOW, 5LL * 1000 * 1000 * 1000)
    ) == 0;
    BOOL barrierPassed = barrierFinished
        && atomic_load(&sBarrierPreCount) == 3
        && atomic_load(&sBarrierPassed) == 1
        && atomic_load(&sBarrierAfterValid) == 1
        && atomic_load(&sBarrierAfterCount) == 2;
    write_line(barrierPassed ? "concurrent barrier: OK" : "concurrent barrier: FAIL");
    passed = passed && barrierPassed;

    dispatch_semaphore_t mainSignal = dispatch_semaphore_create(0);
    atomic_store(&sMainQueueWasMain, 0);
    dispatch_async(dispatch_get_main_queue(), ^{
        atomic_store(&sMainQueueWasMain, pthread_main_np() != 0);
        dispatch_semaphore_signal(mainSignal);
    });
    BOOL mainHop = wait_for_signal(mainSignal) && atomic_load(&sMainQueueWasMain) == 1;
    write_line(mainHop ? "main queue hop: OK" : "main queue hop: FAIL");
    passed = passed && mainHop;

    dispatch_group_t notifyGroup = dispatch_group_create();
    dispatch_semaphore_t notifySignal = dispatch_semaphore_create(0);
    atomic_store(&sGroupWorkFinished, 0);
    atomic_store(&sGroupNotifySawWork, 0);
    dispatch_group_async(notifyGroup, global, ^{
        atomic_store(&sGroupWorkFinished, 1);
    });
    dispatch_group_notify(notifyGroup, global, ^{
        atomic_store(&sGroupNotifySawWork, atomic_load(&sGroupWorkFinished));
        dispatch_semaphore_signal(notifySignal);
    });
    BOOL groupNotify = wait_for_signal(notifySignal)
        && atomic_load(&sGroupWorkFinished) == 1
        && atomic_load(&sGroupNotifySawWork) == 1;
    write_line(groupNotify ? "group notify: OK" : "group notify: FAIL");
    passed = passed && groupNotify;

    dispatch_semaphore_t afterSignal = dispatch_semaphore_create(0);
    atomic_store(&sAfterFired, 0);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10LL * 1000 * 1000), global, ^{
        atomic_store(&sAfterFired, 1);
        dispatch_semaphore_signal(afterSignal);
    });
    BOOL afterFired = wait_for_signal(afterSignal) && atomic_load(&sAfterFired) == 1;
    write_line(afterFired ? "dispatch_after: OK" : "dispatch_after: FAIL");
    passed = passed && afterFired;

    dispatch_semaphore_t timerSignal = dispatch_semaphore_create(0);
    atomic_store(&sTimerFired, 0);
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, global);
    BOOL timerFired = NO;
    if (timer) {
        dispatch_source_set_timer(
            timer, dispatch_time(DISPATCH_TIME_NOW, 10LL * 1000 * 1000), DISPATCH_TIME_FOREVER, 0
        );
        dispatch_source_set_event_handler(timer, ^{
            atomic_store(&sTimerFired, 1);
            dispatch_semaphore_signal(timerSignal);
        });
        dispatch_resume(timer);
        timerFired = wait_for_signal(timerSignal) && atomic_load(&sTimerFired) == 1;
        dispatch_source_cancel(timer);
    }
    write_line(timerFired ? "timer source: OK" : "timer source: FAIL");
    passed = passed && timerFired;

    atomic_store(&sOnceRuns, 0);
    atomic_store(&sOnceValue, 0);
    atomic_store(&sOnceObservers, 0);
    pthread_t workers[2];
    int created = 0;
    for (int index = 0; index < 2; index++) {
        if (pthread_create(&workers[index], NULL, once_worker, NULL) == 0) {
            created++;
        } else {
            break;
        }
    }
    BOOL joinsSucceeded = created == 2;
    for (int index = 0; index < created; index++) {
        if (pthread_join(workers[index], NULL) != 0) {
            joinsSucceeded = NO;
        }
    }
    BOOL oncePassed = joinsSucceeded
        && atomic_load(&sOnceRuns) == 1
        && atomic_load(&sOnceValue) == 42
        && atomic_load(&sOnceObservers) == 2;
    write_line(oncePassed ? "dispatch_once two threads: OK" : "dispatch_once two threads: FAIL");
    passed = passed && oncePassed;

    write_line(passed ? "DISPATCH_OK" : "DISPATCH_FAIL");
    return passed;
}

@interface ViewController ()
@property (nonatomic, strong) UILabel *statusLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    UIStackView *content = [[UIStackView alloc] init];
    content.axis = UILayoutConstraintAxisVertical;
    content.alignment = UIStackViewAlignmentCenter;
    content.spacing = 24;
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:content];

    UILabel *title = [[UILabel alloc] init];
    title.accessibilityIdentifier = @"dispatch.title";
    title.text = @"libdispatch Fixture";
    title.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
    [content addArrangedSubview:title];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.accessibilityIdentifier = @"dispatch.status";
    self.statusLabel.text = @"Dispatch-Ablauf läuft …";
    self.statusLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    [content addArrangedSubview:self.statusLabel];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [content.leadingAnchor constraintGreaterThanOrEqualToAnchor:safeArea.leadingAnchor constant:20],
        [content.trailingAnchor constraintLessThanOrEqualToAnchor:safeArea.trailingAnchor constant:-20],
        [content.centerYAnchor constraintEqualToAnchor:safeArea.centerYAnchor]
    ]];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL passed = run_dispatch_scenario();
        dispatch_async(dispatch_get_main_queue(), ^{
            self.statusLabel.text = passed ? @"DISPATCH_OK" : @"DISPATCH_FAIL";
        });
    });
}

@end