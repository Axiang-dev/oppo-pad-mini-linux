# Changelog

All notable changes are documented here. This project does not yet have a
supported end-user release.

## Unreleased

### Added

- Public source patch for the OPD2515 diagnostic Linux baseline.
- Reproducible source fetch, kernel build, initramfs build, and image packaging
  entry points.
- Hardware support matrix and evidence classification.
- Display bring-up record through EXP-057.
- Repository hygiene, script, Markdown, and patch validation.

### Current limitations

- Native XN254 display output remains black after the firmware splash handoff.
- Adreno GPU acceleration, touchscreen, wireless, audio, charging control, and
  suspend are not implemented.
- Armada OS, desktop, Steam, Gamescope, FEX, Proton, DXVK, and VKD3D-Proton
  integration has not reached a usable-device milestone.