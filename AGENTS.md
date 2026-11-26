# Repository guidance

This project is an unofficial OPD2515 Linux port. Read README.md,
docs/status.md, and docs/evidence.md before changing code or making a status
claim.

## Technical workflow

1. Reproduce the fixed upstream baseline in docs/sources.md.
2. Apply only patches tracked in kernel/patches.
3. Build the kernel, the OPD2515 DTB, and initramfs.
4. Record the exact source commit, configuration hash, commands, output hashes,
   and test environment.
5. Separate direct device evidence, controlled exclusions, source analysis,
   unverified hypotheses, and superseded conclusions.
6. Change one hardware or software behavior per experiment.
7. Update docs/status.md and docs/experiments.md after a meaningful result.

## Device safety

Partition writes require explicit authorization from the device owner for each
operation. The tested local device uses boot_b for reversible experiments, but
that choice does not make boot_b safe on other units.

Never modify the partition table, active slot, AVB trust configuration, or
boot-chain partitions. Never change thermal, charging, or power-protection
limits without measurement and a documented rollback path.

A visible image, repeated cold boot, and recovery return are separate acceptance
criteria. A DRM card, a framebuffer node, a module load, or an increasing frame
counter does not demonstrate visible display output.

## Public repository rules

Do not commit device serial numbers, USB identifiers, MAC addresses, user data,
account credentials, private keys, vendor firmware, complete partition images,
private logs, or build caches. Run tests/check-repository.py before every push.

Do not describe diagnostic patches as upstream-ready. Do not add a working
status without a traceable device result.