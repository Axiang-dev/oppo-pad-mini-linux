# OPD2515 device directory

This directory contains device-specific configuration, patch notes, and
scripts that do not belong in the generic kernel tooling.

Current identifiers:

- Retail model: OPPO Pad Mini OPD2515
- SoC: SM8845P, upstream Molokai
- Tested firmware family: ColorOS 16
- Tested panel binding: `oppo,xn254-p-d-a0040`
- Main tested boot partition during local experiments: `boot_b`

The public repository must remain useful without a local Android checkout.
Hardware evidence and limitations belong in docs/hardware.md,
docs/display.md, and docs/experiments.md.