## Purpose

Describe the one behavioral variable or repository defect this change addresses.

## Evidence

- Source commit:
- Patch SHA256:
- Configuration SHA256:
- Image / DTB / initramfs SHA256:
- Hardware test method:
- Direct device result:
- Controlled exclusions:
- Remaining hypotheses:

## Verification

- [ ] `./tests/check-scripts.sh`
- [ ] `python3 tests/check-markdown.py`
- [ ] `python3 tests/check-repository.py`
- [ ] Pinned-source patch application check
- [ ] Kernel-only build and OPD2515 DTB build, or a documented reason they were not run
- [ ] No credentials, device-unique identifiers, proprietary firmware, partition images, or private logs
- [ ] Documentation distinguishes verified facts from unverified hypotheses

## Recovery

Describe the rollback method and final device state for hardware tests. Partition writes must have explicit owner authorization for each operation.

## Limitations

State what this change does not establish, without promoting compile or counter evidence into a working feature claim.
