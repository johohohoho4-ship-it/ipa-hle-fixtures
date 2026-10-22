#include <dispatch/dispatch.h>
#include <os/lock.h>
#include <pthread.h>
#include <stdatomic.h>
#include <stdint.h>
#include <unistd.h>

#define WORKERS 4
#define ROUNDS 2000
#define QUEUE_ITEMS 500

static pthread_mutex_t counter_lock = PTHREAD_MUTEX_INITIALIZER;
static long mutex_counter;
static os_unfair_lock unfair = OS_UNFAIR_LOCK_INIT;
static long unfair_counter;
static _Atomic long atomic_counter;

static pthread_mutex_t queue_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t queue_nonempty = PTHREAD_COND_INITIALIZER;
static pthread_cond_t queue_nonfull = PTHREAD_COND_INITIALIZER;
static int queue[8];
static int queue_count;
static long consumed_sum;

static dispatch_semaphore_t done;

static void report(const char *message, size_t length) {
    (void)write(2, message, length);
}

#define FAIL(tag, code) do { \
    report("SYNC_FAIL:" tag "\n", sizeof("SYNC_FAIL:" tag "\n") - 1); \
    return code; \
} while (0)

static void *hammer(void *unused) {
    (void)unused;
    for (int i = 0; i < ROUNDS; i++) {
        pthread_mutex_lock(&counter_lock);
        long value = mutex_counter;
        for (volatile int spin = 0; spin < 50; spin++) {
        }
        mutex_counter = value + 1;
        pthread_mutex_unlock(&counter_lock);

        os_unfair_lock_lock(&unfair);
        unfair_counter++;
        os_unfair_lock_unlock(&unfair);

        atomic_fetch_add_explicit(&atomic_counter, 1, memory_order_relaxed);
    }
    dispatch_semaphore_signal(done);
    return 0;
}

static void *produce(void *unused) {
    (void)unused;
    for (int i = 1; i <= QUEUE_ITEMS; i++) {
        pthread_mutex_lock(&queue_lock);
        while (queue_count == 8) {
            pthread_cond_wait(&queue_nonfull, &queue_lock);
        }
        queue[queue_count++] = i;
        pthread_cond_signal(&queue_nonempty);
        pthread_mutex_unlock(&queue_lock);
    }
    return 0;
}

static void *consume(void *unused) {
    (void)unused;
    for (int i = 0; i < QUEUE_ITEMS; i++) {
        pthread_mutex_lock(&queue_lock);
        while (queue_count == 0) {
            pthread_cond_wait(&queue_nonempty, &queue_lock);
        }
        consumed_sum += queue[--queue_count];
        pthread_cond_signal(&queue_nonfull);
        pthread_mutex_unlock(&queue_lock);
    }
    return 0;
}

int sync_stress_run(void) {
    pthread_t workers[WORKERS];
    pthread_t producer;
    pthread_t consumer;

    done = dispatch_semaphore_create(0);
    if (!done) FAIL("semaphore", 10);
    if (dispatch_semaphore_wait(done, DISPATCH_TIME_NOW) == 0) FAIL("semaphore-now", 11);

    for (int i = 0; i < WORKERS; i++) {
        if (pthread_create(&workers[i], 0, hammer, 0) != 0) FAIL("create", 12);
    }
    for (int i = 0; i < WORKERS; i++) {
        if (dispatch_semaphore_wait(done, DISPATCH_TIME_FOREVER) != 0) FAIL("semaphore-wait", 13);
    }
    for (int i = 0; i < WORKERS; i++) {
        if (pthread_join(workers[i], 0) != 0) FAIL("join", 14);
    }
    if (mutex_counter != WORKERS * ROUNDS) FAIL("mutex", 15);
    if (unfair_counter != WORKERS * ROUNDS) FAIL("unfair", 16);
    if (atomic_load(&atomic_counter) != WORKERS * ROUNDS) FAIL("atomic", 17);

    if (pthread_create(&consumer, 0, consume, 0) != 0 ||
        pthread_create(&producer, 0, produce, 0) != 0) FAIL("create-queue", 18);
    if (pthread_join(producer, 0) != 0 || pthread_join(consumer, 0) != 0) FAIL("join-queue", 19);
    if (consumed_sum != (long)QUEUE_ITEMS * (QUEUE_ITEMS + 1) / 2) FAIL("queue", 20);

    if (dispatch_semaphore_wait(done, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_MSEC)) == 0) {
        FAIL("semaphore-timeout", 21);
    }

    (void)write(1, "SYNC_OK:8000:125250\n", sizeof("SYNC_OK:8000:125250\n") - 1);
    return 0;
}
