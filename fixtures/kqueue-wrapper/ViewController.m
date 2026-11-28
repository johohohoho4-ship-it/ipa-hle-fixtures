#import "ViewController.h"
#include <errno.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/event.h>
#include <sys/time.h>
#include <unistd.h>

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    int passed = [self runKqueueChecks];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, 350, 32)];
    title.text = @"Kqueue Wrapper";
    title.font = [UIFont boldSystemFontOfSize:22];
    title.accessibilityIdentifier = @"kq.title";
    [self.view addSubview:title];

    UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(20, 124, 350, 28)];
    status.text = [NSString stringWithFormat:@"Kqueue OK (%d checks)", passed];
    status.font = [UIFont systemFontOfSize:16];
    status.accessibilityIdentifier = @"kq.status";
    [self.view addSubview:status];
}

- (int)runKqueueChecks {
    int passed = 0;
    struct timespec zero = {0, 0};

    // 1. Darwin ARM64 ABI sizes, offsets, and <sys/event.h> constants
    printf("KQ_ABI sizeof=%zu,%zu off=%zu,%zu,%zu,%zu,%zu,%zu,%zu "
           "filt=%d,%d,%d,%d flags=%d,%d,%d,%d,%d,%d,%d,%d,%d trig=%u err=%d,%d,%d\n",
           sizeof(struct kevent),
           sizeof(struct kevent64_s),
           offsetof(struct kevent, ident),
           offsetof(struct kevent, filter),
           offsetof(struct kevent, flags),
           offsetof(struct kevent, fflags),
           offsetof(struct kevent, data),
           offsetof(struct kevent, udata),
           offsetof(struct kevent64_s, ext),
           EVFILT_READ, EVFILT_WRITE, EVFILT_TIMER, EVFILT_USER,
           EV_ADD, EV_DELETE, EV_ENABLE, EV_DISABLE, EV_ONESHOT, EV_CLEAR, EV_RECEIPT, EV_ERROR, EV_EOF,
           (unsigned int)NOTE_TRIGGER,
           EBADF, ENOENT, EINVAL);
    if (sizeof(struct kevent) == 32 && sizeof(struct kevent64_s) == 48 &&
        offsetof(struct kevent, udata) == 24 && offsetof(struct kevent64_s, ext) == 32) {
        passed++;
    }

    // 2. Independent kqueue() descriptors and close() invalidation (EBADF)
    int kq1 = kqueue();
    int kq2 = kqueue();
    int diff = (kq1 >= 0 && kq2 >= 0 && kq1 != kq2) ? 1 : 0;
    int c1 = (kq1 >= 0) ? close(kq1) : -1;
    struct kevent ev;
    memset(&ev, 0, sizeof(ev));
    errno = 0;
    int closed_rc = kevent(kq1, NULL, 0, &ev, 1, &zero);
    int closed_err = errno;
    int open_rc = kevent(kq2, NULL, 0, &ev, 1, &zero);
    printf("KQ_INDEP diff=%d c1=%d closed_rc=%d closed_err=%d open_rc=%d\n",
           diff, c1, closed_rc, closed_err, open_rc);
    if (diff == 1 && c1 == 0 && closed_rc == -1 && closed_err == EBADF && open_rc == 0) {
        passed++;
    }

    // 3. EVFILT_USER: EV_ADD | EV_CLEAR, NOTE_TRIGGER, NOTE_FFCOPY/NOTE_FFOR, udata, EV_DISABLE/EV_ENABLE, EV_DELETE -> ENOENT
    struct kevent ch;
    void *user_ud = (void *)(uintptr_t)0x1234;
    EV_SET(&ch, 0x101, EVFILT_USER, EV_ADD | EV_CLEAR, 0, 0, user_ud);
    int r0 = kevent(kq2, &ch, 1, &ev, 1, &zero);

    EV_SET(&ch, 0x101, EVFILT_USER, 0, NOTE_TRIGGER | NOTE_FFCOPY | 0x42, 0, user_ud);
    int r1 = kevent(kq2, &ch, 1, &ev, 1, &zero);
    unsigned long id1 = (unsigned long)ev.ident;
    int filt1 = ev.filter;
    unsigned int ff1 = ev.fflags;
    unsigned long ud1 = (unsigned long)(uintptr_t)ev.udata;

    int r2 = kevent(kq2, NULL, 0, &ev, 1, &zero);

    EV_SET(&ch, 0x101, EVFILT_USER, EV_DISABLE, 0, 0, user_ud);
    kevent(kq2, &ch, 1, NULL, 0, &zero);
    EV_SET(&ch, 0x101, EVFILT_USER, 0, NOTE_FFCOPY | 0x05, 0, user_ud);
    kevent(kq2, &ch, 1, &ev, 1, &zero);
    EV_SET(&ch, 0x101, EVFILT_USER, 0, NOTE_TRIGGER | NOTE_FFOR | 0x100, 0, user_ud);
    int dis_rc = kevent(kq2, &ch, 1, &ev, 1, &zero);

    EV_SET(&ch, 0x101, EVFILT_USER, EV_ENABLE, 0, 0, user_ud);
    int en_rc = kevent(kq2, &ch, 1, &ev, 1, &zero);
    unsigned int ff2 = ev.fflags;

    EV_SET(&ch, 0x101, EVFILT_USER, EV_DELETE, 0, 0, NULL);
    int del1 = kevent(kq2, &ch, 1, &ev, 1, &zero);
    int del2 = kevent(kq2, &ch, 1, &ev, 1, &zero);
    int del2_err = (ev.flags & EV_ERROR) ? 1 : 0;
    long del2_eno = (long)ev.data;

    printf("KQ_USER r0=%d r1=%d id=%lx filt=%d ff1=%x ud1=%lx r2=%d dis=%d en=%d ff2=%x del1=%d del2=%d err=%d eno=%ld\n",
           r0, r1, id1, filt1, ff1, ud1, r2, dis_rc, en_rc, ff2, del1, del2, del2_err, del2_eno);
    if (r0 == 0 && r1 == 1 && id1 == 0x101 && filt1 == EVFILT_USER &&
        ff1 == 0x42 && ud1 == 0x1234 && r2 == 0 && dis_rc == 0 &&
        en_rc == 1 && ff2 == 0x105 && del1 == 0 && del2 == 1 &&
        del2_err == 1 && del2_eno == ENOENT) {
        passed++;
    }

    // 4. Pipe + EVFILT_READ / EVFILT_WRITE + EV_EOF via libSystem wrappers
    int fds[2] = {-1, -1};
    int prc = pipe(fds);
    struct kevent pch[2];
    struct kevent pev[2];
    EV_SET(&pch[0], fds[0], EVFILT_READ, EV_ADD, 0, 0, (void *)(uintptr_t)0x5678);
    EV_SET(&pch[1], fds[1], EVFILT_WRITE, EV_ADD, 0, 0, (void *)(uintptr_t)0x9abc);
    int init_rc = kevent(kq2, pch, 2, pev, 2, &zero);
    int w_filt = (init_rc >= 1) ? pev[0].filter : 0;
    int w_pos = (init_rc >= 1 && pev[0].data > 0) ? 1 : 0;
    unsigned long w_ud = (init_rc >= 1) ? (unsigned long)(uintptr_t)pev[0].udata : 0;

    EV_SET(&ch, fds[1], EVFILT_WRITE, EV_DELETE, 0, 0, NULL);
    kevent(kq2, &ch, 1, NULL, 0, &zero);

    ssize_t wrc = write(fds[1], "hello", 5);
    int rd_rc = kevent(kq2, NULL, 0, &ev, 1, &zero);
    long rd_data = (rd_rc == 1) ? (long)ev.data : -1;
    unsigned long rd_ud = (rd_rc == 1) ? (unsigned long)(uintptr_t)ev.udata : 0;

    char buf[8];
    memset(buf, 0, sizeof(buf));
    ssize_t rbytes = read(fds[0], buf, 5);
    int rd_ok = (rbytes == 5 && memcmp(buf, "hello", 5) == 0) ? 1 : 0;
    int empty_rc = kevent(kq2, NULL, 0, &ev, 1, &zero);

    close(fds[1]);
    int eof_rc = kevent(kq2, NULL, 0, &ev, 1, &zero);
    int eof_flag = (eof_rc == 1 && (ev.flags & EV_EOF)) ? 1 : 0;
    long eof_data = (eof_rc == 1) ? (long)ev.data : -1;

    EV_SET(&ch, fds[0], EVFILT_READ, EV_DELETE, 0, 0, NULL);
    kevent(kq2, &ch, 1, NULL, 0, &zero);
    close(fds[0]);

    printf("KQ_PIPE prc=%d init=%d w_filt=%d w_pos=%d w_ud=%lx wrc=%ld rd=%d rd_data=%ld rd_ud=%lx rd_ok=%d empty=%d eof_rc=%d eof=%d eof_data=%ld\n",
           prc, init_rc, w_filt, w_pos, w_ud, (long)wrc, rd_rc, rd_data, rd_ud, rd_ok, empty_rc, eof_rc, eof_flag, eof_data);
    if (prc == 0 && init_rc == 1 && w_filt == EVFILT_WRITE && w_pos == 1 &&
        w_ud == 0x9abc && wrc == 5 && rd_rc == 1 && rd_data == 5 &&
        rd_ud == 0x5678 && rd_ok == 1 && empty_rc == 0 &&
        eof_rc == 1 && eof_flag == 1 && eof_data == 0) {
        passed++;
    }

    // 5. EVFILT_TIMER (5 ms, EV_ONESHOT) with 200 ms timeout
    struct timespec ts_wait = {0, 200000000};
    EV_SET(&ch, 77, EVFILT_TIMER, EV_ADD | EV_ONESHOT, 0, 5, (void *)(uintptr_t)0xfeed);
    int t_rc = kevent(kq2, &ch, 1, &ev, 1, &ts_wait);
    unsigned long t_id = (t_rc == 1) ? (unsigned long)ev.ident : 0;
    int t_filt = (t_rc == 1) ? ev.filter : 0;
    int t_fired = (t_rc == 1 && ev.data >= 1) ? 1 : 0;
    unsigned long t_ud = (t_rc == 1) ? (unsigned long)(uintptr_t)ev.udata : 0;
    int t_after = kevent(kq2, NULL, 0, &ev, 1, &zero);
    printf("KQ_TIMER rc=%d id=%lu filt=%d fired=%d ud=%lx after=%d\n",
           t_rc, t_id, t_filt, t_fired, t_ud, t_after);
    if (t_rc == 1 && t_id == 77 && t_filt == EVFILT_TIMER &&
        t_fired == 1 && t_ud == 0xfeed && t_after == 0) {
        passed++;
    }

    // 6. EV_RECEIPT returns EV_ERROR with data=0 on success
    EV_SET(&ch, 0x102, EVFILT_USER, EV_ADD | EV_RECEIPT, 0, 0, (void *)(uintptr_t)0xaaaa);
    int rec_rc = kevent(kq2, &ch, 1, &ev, 1, &zero);
    unsigned long rec_id = (rec_rc == 1) ? (unsigned long)ev.ident : 0;
    int rec_filt = (rec_rc == 1) ? ev.filter : 0;
    int rec_err = (rec_rc == 1 && (ev.flags & EV_ERROR)) ? 1 : 0;
    long rec_data = (rec_rc == 1) ? (long)ev.data : -1;
    unsigned long rec_ud = (rec_rc == 1) ? (unsigned long)(uintptr_t)ev.udata : 0;
    EV_SET(&ch, 0x102, EVFILT_USER, EV_DELETE, 0, 0, NULL);
    kevent(kq2, &ch, 1, NULL, 0, &zero);
    printf("KQ_RECEIPT rc=%d id=%lx filt=%d err=%d data=%ld ud=%lx\n",
           rec_rc, rec_id, rec_filt, rec_err, rec_data, rec_ud);
    if (rec_rc == 1 && rec_id == 0x102 && rec_filt == EVFILT_USER &&
        rec_err == 1 && rec_data == 0 && rec_ud == 0xaaaa) {
        passed++;
    }

    // 7. kevent64() with EVFILT_USER and 64-bit udata
    struct kevent64_s ch64;
    struct kevent64_s ev64;
    memset(&ch64, 0, sizeof(ch64));
    memset(&ev64, 0, sizeof(ev64));
    ch64.ident = 0x202;
    ch64.filter = EVFILT_USER;
    ch64.flags = EV_ADD | EV_CLEAR;
    ch64.udata = 0xCAFEBABE11223344ULL;
    int k64_r0 = kevent64(kq2, &ch64, 1, &ev64, 1, 0, &zero);

    ch64.flags = 0;
    ch64.fflags = NOTE_TRIGGER | NOTE_FFCOPY | 0x77;
    int k64_r1 = kevent64(kq2, &ch64, 1, &ev64, 1, 0, &zero);

    ch64.flags = EV_DELETE;
    ch64.fflags = 0;
    kevent64(kq2, &ch64, 1, NULL, 0, 0, &zero);

    printf("KQ_KEVENT64 r0=%d r1=%d id=%llx filt=%d ff=%x ud=%llx ext=%llu,%llu\n",
           k64_r0, k64_r1,
           (unsigned long long)ev64.ident,
           (int)ev64.filter,
           (unsigned int)ev64.fflags,
           (unsigned long long)ev64.udata,
           (unsigned long long)ev64.ext[0],
           (unsigned long long)ev64.ext[1]);
    if (k64_r0 == 0 && k64_r1 == 1 && ev64.ident == 0x202 &&
        ev64.filter == EVFILT_USER && ev64.fflags == 0x77 &&
        ev64.udata == 0xCAFEBABE11223344ULL && ev64.ext[0] == 0 && ev64.ext[1] == 0) {
        passed++;
    }

    // 8. Error handling: invalid kq (-1 -> EBADF), non-kqueue fd (-> EBADF), invalid timeout (-> EINVAL)
    errno = 0;
    int neg_rc = kevent(-1, NULL, 0, &ev, 1, &zero);
    int neg_err = errno;

    int efds[2] = {-1, -1};
    pipe(efds);
    errno = 0;
    int pipe_rc = kevent(efds[0], NULL, 0, &ev, 1, &zero);
    int pipe_err = errno;
    close(efds[0]);
    close(efds[1]);

    struct timespec bad_ts = {-1, 0};
    errno = 0;
    int ts_rc = kevent(kq2, NULL, 0, &ev, 1, &bad_ts);
    int ts_err = errno;

    int c2 = close(kq2);
    printf("KQ_ERRORS neg_rc=%d neg_err=%d pipe_rc=%d pipe_err=%d ts_rc=%d ts_err=%d close=%d\n",
           neg_rc, neg_err, pipe_rc, pipe_err, ts_rc, ts_err, c2);
    if (neg_rc == -1 && neg_err == EBADF &&
        pipe_rc == -1 && pipe_err == EBADF &&
        ts_rc == -1 && ts_err == EINVAL && c2 == 0) {
        passed++;
    }

    printf("KQ_DONE checks=%d\n", passed);
    return passed;
}

@end
