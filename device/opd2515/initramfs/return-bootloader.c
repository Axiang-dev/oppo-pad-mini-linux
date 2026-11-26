// SPDX-License-Identifier: GPL-2.0-only
#define _GNU_SOURCE
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <sys/reboot.h>
#include <sys/syscall.h>
#include <unistd.h>

int main(void)
{
    const char reason[] = "bootloader";

    errno = 0;
    syscall(SYS_reboot, LINUX_REBOOT_MAGIC1, LINUX_REBOOT_MAGIC2,
            LINUX_REBOOT_CMD_RESTART2, reason);
    fprintf(stderr, "restart2 bootloader failed: %s\n", strerror(errno));
    return 1;
}
