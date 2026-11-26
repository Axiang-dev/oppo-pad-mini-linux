# Testing and evidence capture

A hardware test must be designed around the decision it will change. Capture the
cheapest evidence that can resolve that decision, and do not promote unrelated
signals into a feature claim.

## Before the test

Record:

- device model and firmware family without a unique serial number
- source commit and patch hashes
- config, Image, DTB, modules, initramfs, and candidate hashes
- the one behavioral variable
- the expected observation and a negative-control condition
- the exact recovery path and test-stop state
- whether a partition write is authorized

## Display evidence fields

Keep separate records for:

- visual result before and after firmware splash handoff
- physical panel or external-camera observation
- DPU LM CRC
- DPU INTF CRC
- DSI command MISR or transport counters
- DPU frame completion and TE pointer movement
- SMMU context faults
- DSI FIFO, ACK error, timeout, and PLL status
- underrun and vblank timeout reports
- final USB and Fastboot state

## Evidence promotion

A feature is not Working until the normal user entry point reaches it after a
clean cold boot, a user-visible or externally measurable result is captured, the
result repeats, and recovery remains available.

The following are not standalone success criteria:

- source compile
- module load
- sysfs or debugfs node exists
- DRM card or framebuffer exists
- CRC values change in SoC memory
- IRQ or pointer counters rise
- a screenshot is produced while the panel is dark
- USB enumeration after a failed display path

## Negative results

Preserve failed candidates, photographs, raw logs in the private archive, and the
source diff under `kernel/patches/experiments/` when it remains useful. Mark a
patch rejected when a controlled experiment rules it out. Do not repeat a failed
experiment without a new decision-changing reason.

## Sanitization

Before publishing a result:

- remove device serial numbers, USB instance details, MAC addresses, IMEI, and
  account identifiers
- remove full vendor firmware or partition data
- remove absolute host paths
- hash candidates with SHA256
- quote only the relevant log span and include surrounding context needed to
  interpret it
- distinguish direct observation from interpretation
