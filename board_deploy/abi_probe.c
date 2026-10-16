/* Minimal ABI compatibility probe.
 *
 * The whole native-app plan rests on the Windows ARM cross compiler producing a binary that this
 * particular Yocto rootfs will run. The usual failure is glibc symbol versions: the toolchain
 * bundles its own libc headers, so a program built here links against whatever GLIBC_2.x versions
 * the toolchain assumes, and if the board's libc is older the loader refuses to start it.
 *
 * This prints the glibc the binary was built against, the one it actually runs on, and touches a
 * few things the real program needs (pthread, math, mmap) so a pass here means something.
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <pthread.h>
#include <math.h>
#include <sys/mman.h>
#include <gnu/libc-version.h>

static void *worker(void *arg) {
    (void)arg;
    return (void *)42;
}

int main(void) {
    printf("HELLO_FROM_CROSS\n");
    printf("build glibc : %s\n", gnu_get_libc_version());

    pthread_t t;
    void *ret = NULL;
    pthread_create(&t, NULL, worker, NULL);
    pthread_join(t, &ret);
    printf("pthread ret : %ld\n", (long)ret);

    volatile double d = sqrt(2.0);
    printf("sqrt(2)     : %.6f\n", d);

    /* /dev/mem mmap is the mechanism the real app uses to read the camera frame buffer */
    int fd = open("/dev/mem", O_RDONLY | O_SYNC);
    if (fd < 0) { printf("open /dev/mem: FAILED\n"); return 1; }
    void *p = mmap(NULL, 4096, PROT_READ, MAP_SHARED, fd, 0x41220000UL);
    if (p == MAP_FAILED) { printf("mmap 0x41220000: FAILED\n"); close(fd); return 1; }
    printf("mmap dbg_gpio:  OK, word=0x%08X\n", *(volatile unsigned int *)p);
    munmap(p, 4096);
    close(fd);

    printf("ABI_PROBE_OK\n");
    return 0;
}
