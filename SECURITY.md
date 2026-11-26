# Security policy

This repository contains experimental device-port code and diagnostic patches.
It does not provide a production security guarantee.

Do not report passwords, access tokens, device serial numbers, private partition
images, or personal logs in a public issue. Report a repository credential leak
through GitHub's private vulnerability reporting interface for this repository
when available.

For a boot-chain or data-loss problem, stop the device experiment and preserve
the original partition backup and its checksum. Do not attempt an unreviewed
repair sequence on an additional device.

The project will publish a replacement or history-rewrite notice when a leaked
credential or personal identifier is discovered. Published Git history is not
rewritten without explicit maintainer approval.