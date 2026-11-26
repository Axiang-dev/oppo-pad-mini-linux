#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
set +e
MODDIR=/modules

log() {
    printf '%s\n' "$*"
    printf '%s\n' "$*" >/dev/kmsg
}

load_module() {
    name=$1
    shift
    /bin/busybox insmod "$MODDIR/$name" "$@"
    result=$?
    log "OPD2515 module $name returned $result"
    return "$result"
}

log 'OPD2515 display module load start'

for module in \
    cec.ko \
    drm_exec.ko \
    gpu-sched.ko \
    drm_gpuvm.ko \
    drm_client_lib.ko \
    mdt_loader.ko \
    ubwc_config.ko \
    drm_display_helper.ko \
    dispcc-kaanapali.ko; do
    load_module "$module" || log "OPD2515 dependency failed: $module"
done

load_module panel-oppo-xn254.ko
panel_result=$?
load_module msm.ko
msm_result=$?

log 'OPD2515 display module load complete'
if [ "$msm_result" -ne 0 ]; then
    exit "$msm_result"
fi
exit "$panel_result"
