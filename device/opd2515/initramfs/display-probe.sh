#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
# Run from the OPD2515 RAM initramfs after the diagnostic modules load.
set -eu

fb=/sys/class/graphics/fb0/name
tty=/sys/class/tty/tty0/active
irq=/sys/kernel/debug/dri/0/debug/core_irq
kms=/sys/kernel/debug/dri/0/kms

test -r "$fb"
test -r "$tty"
test -c /dev/tty1
/bin/busybox grep -q ' /sys/kernel/debug debugfs ' /proc/mounts || \
    mount -t debugfs debugfs /sys/kernel/debug
test -r "$irq"

printk=$(/bin/busybox cat /proc/sys/kernel/printk)
cursor_file=/sys/class/graphics/fbcon/cursor_blink
cursor_blink=
restore_console() {
    printf '%s\n' "$printk" > /proc/sys/kernel/printk
    if [ -n "$cursor_blink" ]; then
        printf '%s\n' "$cursor_blink" >"$cursor_file"
    fi
}
trap restore_console EXIT

printf '1\n' > /proc/sys/kernel/printk
if [ -w "$cursor_file" ]; then
    cursor_blink=$(/bin/busybox cat "$cursor_file")
    printf '0\n' >"$cursor_file"
fi

show_frame() {
    label=$1
    colour=$2
    printf '\033[0;97;%sm\033[2J\033[H%s\n' "$colour" "$label" >/dev/tty1
}

snapshot() {
    label=$1
    printf '\nOPD2515_SAMPLE %s uptime=' "$label"
    /bin/busybox cat /proc/uptime
    /bin/busybox cat "$irq"
    /bin/busybox md5sum /dev/fb0
}

if [ "${1:-}" = misr-abba ]; then
    test -r "$kms"
    misr_sample() {
        label=$1
        captured=/run/opd2515-kms-$label.txt
        printf '\nOPD2515_MISR_SAMPLE %s uptime=' "$label"
        /bin/busybox cat /proc/uptime
        snapshot "$label"
        /bin/busybox cat "$kms" >"$captured"
        /bin/busybox awk '
            /^=+/ {
                block = $0
                gsub(/=/, "", block)
                match_dsi = block == "dsi0_ctrl"
            }
            match_dsi && $1 == "0x90" {
                printf "OPD2515_MISR_CMD_CTRL %s\n", $6
            }
            match_dsi && $1 == "0x130" {
                printf "OPD2515_MISR_CMD_MDP0 %s\n", $3
            }
        ' "$captured"
        printf 'OPD2515_SNAPSHOT_SHA256 %s ' "$label"
        /bin/busybox sha256sum "$captured"
    }

    misr_sample ready
    show_frame 'A BLUE' 44
    sleep 3
    misr_sample blue_first
    show_frame 'B RED' 41
    sleep 3
    misr_sample red
    show_frame 'A BLUE' 44
    sleep 3
    misr_sample blue_return
    printf '\nOPD2515_TRANSPORT_LOG\n'
    /bin/busybox dmesg | /bin/busybox grep -iE \
        'dsi_err_worker|FIFO_STATUS|TIMEOUT_STATUS|ACK_ERR_STATUS|PLL.*(failed|unlock)|smmu.*fault|iommu.*fault|underflow|underrun' || :
    exit 0
fi

snapshot idle_start
sleep 2
show_frame 'A BLUE' 44
snapshot blue
sleep 3
show_frame 'B RED' 41
snapshot red
sleep 3
snapshot red_settled
printf '\nOPD2515_TRANSPORT_LOG\n'
/bin/busybox dmesg | /bin/busybox grep -iE \
    'dsi_err_worker|FIFO_STATUS|TIMEOUT_STATUS|ACK_ERR_STATUS|PLL.*(failed|unlock)|smmu.*fault|iommu.*fault|underflow|underrun' || :
