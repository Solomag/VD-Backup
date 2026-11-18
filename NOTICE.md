# Third-Party Notices

VD-Backup is distributed under the GNU AGPL-3.0-or-later. It also bundles and
distributes third-party software, acknowledged below with its author, license,
and source. Each component remains under its own license.

## mtproto-store

VD-Backup's Telegram backup backend ships the `mtproto-store` binary (bundled in
the release asset) so backups can be stored on Telegram.

- **Project:** mtproto-store
- **Authors:** VictorGabriel7Dev, derived from work by Ash (@ash-iir)
- **License:** GNU AGPL-3.0-or-later
- **Source:** https://github.com/VictorGabriel7Dev/mtproto-store

mtproto-store is free software under the GNU AGPL v3 or later. Under this network
copyleft license, anyone running a modified version (even as a network service)
must offer its corresponding source. The complete, corresponding source for the
version distributed here is available at the URL above.

## Other bundled binaries

VD-Backup also bundles standard command-line tools (such as `tar`, `zstd`, `lz4`,
`rclone`, `restic`, `rsync`, OpenSSH, `age`, `jq`, and `busybox`), built from the
official Termux package repository. Each is under its own upstream license. They
are listed, with versions and provenance, in [docs/BINARIES.md](docs/BINARIES.md).
