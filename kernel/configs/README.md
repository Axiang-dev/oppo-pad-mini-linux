# Kernel configuration

`opd2515-diag68-exp053.config` is the generated configuration used by the
latest reproducible display-handoff candidate. The diagnostic build sets
`CONFIG_INITRAMFS_SOURCE` again after initramfs staging is complete.

The configuration contains OPD2515 diagnostic options and is not a
general-purpose arm64 defconfig. Treat it as an experiment artifact and keep
changes reviewable.