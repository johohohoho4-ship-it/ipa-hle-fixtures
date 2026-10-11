#import "ViewController.h"
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

static BOOL check(const char *name, BOOL passed) {
    printf("C5 %s=%d\n", name, passed ? 1 : 0);
    return passed;
}
static BOOL probe(void) {
    size_t page = (size_t)getpagesize();
    printf("C5 pagesize=%zu\n", page);
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/c5-mapping.bin"];
    int fd = open(path.UTF8String, O_RDWR | O_CREAT | O_TRUNC, 0600);
    if (!check("open", fd >= 0)) return NO;
    unsigned char *seed = malloc(page * 2);
    if (!check("seed_malloc", seed != NULL)) { close(fd); return NO; }
    memset(seed, 'A', page); memset(seed + page, 'B', page);
    BOOL ok = check("seed_write", write(fd, seed, page * 2) == (ssize_t)(page * 2));
    free(seed);
    if (!ok) { close(fd); return NO; }
    volatile unsigned char *one = mmap(NULL, page * 2, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    volatile unsigned char *alias = mmap(NULL, page, PROT_READ, MAP_SHARED, fd, (off_t)page);
    volatile unsigned char *copy = mmap(NULL, page, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, (off_t)page);
    ok &= check("maps", one != MAP_FAILED && alias != MAP_FAILED && copy != MAP_FAILED);
    if (!ok) {
        if (one != MAP_FAILED) munmap((void *)one, page * 2);
        if (alias != MAP_FAILED) munmap((void *)alias, page);
        if (copy != MAP_FAILED) munmap((void *)copy, page);
        close(fd); return NO;
    }
    copy[17] = 'P'; // Establish a private page before the shared write.
    one[page + 17] = 'S';
    ok &= check("shared_store_alias", alias[17] == 'S');
    ok &= check("private_isolation", copy[17] == 'P');
    unsigned char byte = 0;
    ok &= check("seek_read", lseek(fd, (off_t)page + 17, SEEK_SET) == (off_t)page + 17);
    ok &= check("store_fd_read", read(fd, &byte, 1) == 1 && byte == 'S');
    byte = 'D';
    ok &= check("seek_write", lseek(fd, (off_t)page + 18, SEEK_SET) == (off_t)page + 18);
    ok &= check("fd_write", write(fd, &byte, 1) == 1);
    ok &= check("fd_write_alias", alias[18] == 'D' && one[page + 18] == 'D');
    ok &= check("protect_readonly", mprotect((void *)one, page, PROT_READ) == 0);
    ok &= check("partial_unmap", munmap((void *)one, page) == 0);
    one[page + 19] = 'U';
    ok &= check("split_alias", alias[19] == 'U');
    ok &= check("close_fd", close(fd) == 0);
    one[page + 20] = 'C';
    ok &= check("closed_fd_mapping", alias[20] == 'C');
    ok &= check("unmap_remaining", munmap((void *)(one + page), page) == 0);
    ok &= check("unmap_alias", munmap((void *)alias, page) == 0);
    ok &= check("unmap_private", munmap((void *)copy, page) == 0);
    size_t large = 200 * 1024 * 1024;
    volatile unsigned char *heap = malloc(large);
    if (!check("malloc_200_mib", heap != NULL)) return NO;
    heap[0] = 11; heap[page] = 22; heap[large - 1] = 33;
    ok &= check("large_boundaries", heap[0] == 11 && heap[page] == 22 && heap[large - 1] == 33);
    free((void *)heap);
    heap = malloc(large);
    ok &= check("malloc_after_free", heap != NULL);
    if (heap) free((void *)heap);
    printf("C5 %s\n", ok ? "MEMORY_OK" : "MEMORY_FAILED");
    return ok;
}
@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad]; self.view.backgroundColor = UIColor.whiteColor;
    BOOL ok = probe();
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 140, 340, 60)];
    label.text = ok ? @"MEMORY_OK" : @"MEMORY_FAILED";
    label.accessibilityIdentifier = @"memory.status";
    [self.view addSubview:label];
}
@end
