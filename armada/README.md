# Armada OS integration

Armada OS integration has not reached a tested milestone for OPD2515.

The current source tree provides a diagnostic Linux kernel and USB-accessible
RAM initramfs. Any future Armada layer must retain the documented boot,
recovery, power, and thermal safety requirements. Do not publish an installer
until a device can cold boot into the user-visible operating system and return
to the original software through a tested recovery path.