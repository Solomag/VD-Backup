# VDLU release step - VD-Backup

VD-Backup carries the vendored VDLU engine (`module/vdlu/`, profile `hardened`). Besides the usual
flashable `.zip` assets, each release also publishes a content-addressed feed (`manifest.json` + `blobs/`)
so installed devices update **flashlessly and incrementally** - fetching only the files that changed,
applying the live ones without a reboot. The `.zip` stays the first-install and fallback path; VDLU is
additive and never replaces it.

The feed is produced by the canonical tools in `VD/Sources/VDLiveUpdate/producer/` and consumed by the
vendored engine here. The private signing key stays with the release operator, never in the repo or on a
device (`VDLiveUpdate/keys/vd-2026.pem`, gitignored); only `vd-2026.pub` is embarked, in
`module/vdlu/keyring/`. Contract: `VDLiveUpdate/INTERFACES.md` §3/§6; architecture:
`MODULO_VDLU.md` §12/§13 (the VDLU design doc).

## Prerequisites

- `python3` and `openssl` (3.x) on the build host (the producer tools, not the device).
- The private key `VD/Sources/VDLiveUpdate/keys/vd-2026.pem`. Its public half is already embarked at
  `module/vdlu/keyring/vd-2026.pub` and its `key_id` is `vd-2026`.
- The final module tree the `.zip` ships - the same tree assembled in CI after the binaries are built and
  `README.md`/`LICENSE` are staged (`.github/workflows/VD-Backup.yml`), i.e. `module/` post-packaging. The
  feed must be packed from that exact tree so every published blob reverifies against what users flash.

## Steps (per release, after the `.zip` assets are built)

```sh
VDLU=../VDLiveUpdate                 # VD/Sources/VDLiveUpdate
TREE=module                          # the final module tree (same contents the .zip ships)
OUT=./vdlu-feed                      # manifest.json + blobs/ land here
VER=10500                            # module.prop versionCode (monotonic; hardened blocks downgrade)
NAME=v1.05                           # module.prop versionName

# 1. pack the tree into a content-addressed feed (dedup; --prev computes delete[]).
"$VDLU/producer/vdlu-pack" "$TREE" "$OUT" vdbackup "$VER" --version-name "$NAME" --channel stable \
    [--prev ./prev-feed/manifest.json]

# 2. sign the manifest in place (ed25519; key_id must match the embarked pubkey).
"$VDLU/producer/vdlu-sign" "$OUT/manifest.json" "$VDLU/keys/vd-2026.pem" vd-2026
```

- `module` is `id=vdbackup`, so the `vdlu-pack` module id is `vdbackup`; the feed is published under the
  `source` the config seeds (`https://vd171.github.io/VD-Modules/VD-Backup`), a path that keeps the repo
  name. `version` is the numeric `versionCode` - the engine compares it monotonically and, under
  `profile=hardened`, refuses a manifest older than the installed one.
- VD-Backup packs a single feed from the universal tree; the per-ABI pruning that produces the `-full` /
  `-lite` `.zip` variants does not fork the feed. The `bin/<abi>/` the live device keeps is already on
  disk, so unchanged binaries are never refetched (content-addressed dedup), and no blob is `reboot`-class
  (VD-Backup is self-contained: no `zygisk/`, no `system/`, no real `sepolicy.rule`), so every update
  applies live.

## Retention (prune orphan blobs)

Blobs are content-addressed and immutable: the packer dedups by sha256 and only ever ADDS, so `blobs/`
grows every release. Keep the feed (and the Pages site) small with `vdlu-gc`, which removes blobs that NO
retained manifest references. Archive each signed manifest first so the GC has version history, then prune
(dry-run by default, `--apply` to delete):

```sh
FEED=<the feed dir produced above>              # manifest.json + blobs/
VDLU=../../VDLiveUpdate                          # canonical producer
mkdir -p "$FEED/manifests"
cp "$FEED/manifest.json" "$FEED/manifests/<versionCode>.json"   # archive the SIGNED manifest
"$VDLU/producer/vdlu-gc" "$FEED" --keep-last 3                  # dry-run: lists orphans
"$VDLU/producer/vdlu-gc" "$FEED" --keep-last 3 --apply          # delete them
```

Retention is by REFERENCE, not age: GC keeps the union of sha256 over the current manifest plus the last 3
archived versions, and never removes a blob a retained release still needs (fail-safe: it refuses to run
with no retained manifest). Deleting a blob frees the Pages site but not git history - keep the public feed
on a dedicated, squashable/orphan branch; blobs are reproducible from the tagged commit by `vdlu-pack`, so
resetting the feed branch loses nothing.

## Publish

Push `vdlu-feed/{manifest.json,blobs/}` to the Pages tree of `VD-Modules` under `VD-Backup/`, in one
spaced batch (never file-by-file live - the GitHub write rules, `MODULO_VDLU.md` §2/§13). Keep the
previous release's feed around to pass as `--prev` next time so `delete[]` prunes removed paths.

## Key rotation

Add the new `vd-<year>.pub` to `module/vdlu/keyring/` **alongside** the old one and sign with the new
`key_id`; the engine accepts any pubkey in the keyring whose id matches the manifest's `key_id`, so a
rotated key never bricks an older install. Drop a retired pubkey only once no reachable device still runs
a manifest signed by it.

---
generated with Claude
