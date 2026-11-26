# Contributing

Bug reports, hardware results, and source patches are welcome.

## Before opening a change

Read docs/status.md, docs/evidence.md, and docs/building.md. Search the existing
experiment record before repeating a failed test. Keep one behavioral variable
per experiment.

## Patch requirements

- Base kernel work on the commit recorded in docs/sources.md.
- Keep diagnostic instrumentation separate from the upstream-ready driver path.
- Preserve SPDX identifiers, copyright notices, and authorship.
- Include the device model, firmware build, source commit, configuration hash,
  test method, observed result, and rollback method for hardware changes.
- Avoid local absolute paths and device serial numbers.
- Do not include firmware, partition images, logs with personal data, or build
  products.

Use an English commit subject in the Linux style, for example:

```text
drm/msm/dsi: enable command MISR on OPD2515
```

The commit body should explain the cause, implementation, evidence, and known
limitations.

## Developer Certificate of Origin

Contributors must be able to certify the Developer Certificate of Origin 1.1
for their contribution. Add a `Signed-off-by` trailer only when you understand
and accept that attestation. Do not sign for another person.

## Verification

Run the repository checks before requesting review:

```sh
./tests/check-scripts.sh
python3 tests/check-repository.py
```

Kernel patches should also pass the patch application check described in
docs/building.md.

## Conduct

Discuss technical evidence directly. Do not expose another person's device
identifiers, private logs, or credentials. Reproduce a result before promoting
an experimental feature to a supported status.