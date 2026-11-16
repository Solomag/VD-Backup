# vdlu-pack (vendored, keyless)

Byte-identical copy of the canonical VDLU producer `vdlu-pack`, vendored so the
github CI can generate per-variant `vdlu/baseline.json` (the install "from:0" seed)
**without any private key** - `vdlu-pack` only hashes + gzips, it never signs.

- Source   : VD/Sources/VDLiveUpdate/producer/vdlu-pack
- Commit    : 2275e4f355b9f5076d99b57013b1699f73f0bb7f
- sha256    : 83602389ee91827e8fc199fbad10ad2a8610f12139a2b2cc7f91485915d167bc
- Stdlib-only (argparse, hashlib, json, os, shutil, subprocess, sys); no local imports.

The signed FEED (for the Pages site) is still produced + signed on the release
operator's machine with the private key; only the keyless baseline runs in CI.
Resync this file (and the sha above) whenever the canonical `vdlu-pack` changes.

generated with Claude
