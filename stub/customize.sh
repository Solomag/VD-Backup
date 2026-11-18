#!/system/bin/sh
# VD-Backup MMRL stub installer. A minimal module (the VDLU flashless updater + a static curl)
# that fits under the MMRL ~50 MB install cap; on first boot it fetches the full VD-Backup via
# VDLU and becomes the real module in place. See stub/README.md.

ui_print ""
ui_print "  VD BACKUP (MMRL stub)"
ui_print "  Fetches the full module on first boot."
ui_print "  https://github.com/VD171/VD-Backup"
ui_print ""

# manager-only (not recovery): the stub needs a booted system to self-update
[ "$BOOTMODE" = true ] || { ui_print "! Install from KernelSU / APatch / Magisk manager (not recovery)."; abort "! Aborting."; }

API="$(getprop ro.build.version.sdk)"
[ "${API:-0}" -ge 26 ] 2>/dev/null || { ui_print "! Android 8.0 (API 26) or newer is required (found API $API)."; abort "! Aborting."; }

case "$ARCH" in
  arm64) ABIDIR=arm64-v8a ;;
  arm)   ABIDIR=armeabi-v7a ;;
  x86)   ABIDIR=x86 ;;
  x64)   ABIDIR=x86_64 ;;
  *) ui_print "! Unsupported architecture: $ARCH"; abort "! Aborting." ;;
esac
ui_print "- Architecture: $ARCH ($ABIDIR)"

# keep only this device's ABI for the bundled curl and the ed25519-mini verifier
if [ -d "$MODPATH/bin" ]; then
  for d in "$MODPATH"/bin/*/; do [ "$(basename "$d")" = "$ABIDIR" ] || rm -rf "$d"; done
fi
if [ -d "$MODPATH/vdlu/verify" ]; then
  for d in "$MODPATH"/vdlu/verify/*/; do [ "$(basename "$d")" = "$ABIDIR" ] || rm -rf "$d"; done
fi

# seed the VDLU config in Tier-2 so the first boot (and the full module afterwards) self-updates
STATE_DIR=/data/adb/vdbackup
if [ ! -f "$STATE_DIR/vdlu/config" ] && [ -f "$MODPATH/vdlu/config.default" ]; then
  ui_print "- Seeding update engine (VDLU) configuration"
  mkdir -p "$STATE_DIR/vdlu"; cp -f "$MODPATH/vdlu/config.default" "$STATE_DIR/vdlu/config"; chmod 600 "$STATE_DIR/vdlu/config"
fi

set_perm_recursive "$MODPATH" 0 0 0755 0644
[ -d "$MODPATH/bin/$ABIDIR" ] && set_perm_recursive "$MODPATH/bin/$ABIDIR" 0 0 0755 0755
[ -d "$MODPATH/vdlu" ] && set_perm_recursive "$MODPATH/vdlu" 0 0 0755 0755

ui_print "- Installed. Reboot; the full module downloads itself on first boot (needs a network)."
ui_print "  Progress: /data/adb/vdbackup/vdlu/boot.log"
