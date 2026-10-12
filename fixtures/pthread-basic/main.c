#include <pthread.h>
#include <stdint.h>
#include <unistd.h>

typedef struct {
    pthread_key_t key;
    uintptr_t tag;
    uintptr_t result;
} Worker;

static void report(const char *message, size_t length) {
    (void)write(2, message, length);
}

static void *run_worker(void *opaque) {
    Worker *worker = (Worker *)opaque;
    if (pthread_setspecific(worker->key, &worker->tag) != 0) {
        return 0;
    }
    if (pthread_getspecific(worker->key) != &worker->tag) {
        return 0;
    }
    return &worker->result;
}

int pthread_basic_run(void) {
    pthread_key_t key;
    pthread_t first;
    pthread_t second;
    void *first_result = 0;
    void *second_result = 0;
    Worker workers[2];

    if (pthread_key_create(&key, 0) != 0) {
        report("PTHREAD_FAIL:key\n", sizeof("PTHREAD_FAIL:key\n") - 1);
        return 10;
    }
    workers[0] = (Worker){key, 0x101, 17};
    workers[1] = (Worker){key, 0x202, 23};

    if (pthread_create(&first, 0, run_worker, &workers[0]) != 0) {
        report("PTHREAD_FAIL:create1\n", sizeof("PTHREAD_FAIL:create1\n") - 1);
        return 11;
    }
    if (pthread_create(&second, 0, run_worker, &workers[1]) != 0) {
        report("PTHREAD_FAIL:create2\n", sizeof("PTHREAD_FAIL:create2\n") - 1);
        return 12;
    }
    if (pthread_join(second, &second_result) != 0 ||
        pthread_join(first, &first_result) != 0) {
        report("PTHREAD_FAIL:join\n", sizeof("PTHREAD_FAIL:join\n") - 1);
        return 13;
    }
    if (first_result != &workers[0].result || second_result != &workers[1].result ||
        *(uintptr_t *)first_result != 17 || *(uintptr_t *)second_result != 23) {
        report("PTHREAD_FAIL:result\n", sizeof("PTHREAD_FAIL:result\n") - 1);
        return 14;
    }
    if (pthread_getspecific(key) != 0) {
        report("PTHREAD_FAIL:tls-main\n", sizeof("PTHREAD_FAIL:tls-main\n") - 1);
        return 15;
    }
    if (pthread_key_delete(key) != 0) {
        report("PTHREAD_FAIL:key-delete\n", sizeof("PTHREAD_FAIL:key-delete\n") - 1);
        return 16;
    }

    (void)write(1, "PTHREAD_OK:17:23\n", sizeof("PTHREAD_OK:17:23\n") - 1);
    return 0;
}

#ifndef PTHREAD_BASIC_NO_MAIN
int main(void) {
    return pthread_basic_run();
}
#endif