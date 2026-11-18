#!/system/bin/sh
# VD-Backup MMRL stub boot service: on first boot, fetch the full module via the VDLU flashless
# updater and apply it in place. Once that lands, the full module's own service.sh replaces this
# one and takes over on later boots. See stub/README.md.

d="${0%/*}"; [ "$d" = "$0" ] && d="."; MODDIR="$(cd "$d" 2>/dev/null && pwd || echo "$d")"
STATE_DIR=/data/adb/vdbackup
VDLU_DIR="$STATE_DIR/vdlu"

# wait for boot + network to settle (the fetch needs the framework up)
until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 2; done
sleep 5

[ -f "$MODDIR/vdlu/update.sh" ] || exit 0

# seed the config if the installer did not (fail-safe)
if [ ! -f "$VDLU_DIR/config" ] && [ -f "$MODDIR/vdlu/config.default" ]; then
  mkdir -p "$VDLU_DIR"; cp -f "$MODDIR/vdlu/config.default" "$VDLU_DIR/config"; chmod 600 "$VDLU_DIR/config"
fi

case "$(getprop ro.product.cpu.abi)" in
  arm64-v8a) VBINABI=arm64-v8a ;; armeabi-v7a) VBINABI=armeabi-v7a ;;
  x86_64) VBINABI=x86_64 ;; x86) VBINABI=x86 ;; *) VBINABI=arm64-v8a ;;
esac

# Unlike the full module, the stub always runs the fetch (it is useless without the payload), not
# only when auto_on_reboot=1. Detached, so a slow or unreachable feed never blocks boot.
setsid nohup sh -c '
  BA="$3"
  export PATH="$1/bin/$BA:/system/bin:/system/xbin:$PATH"
  export LD_LIBRARY_PATH="$1/bin/$BA/lib:${LD_LIBRARY_PATH:-}"
  export VDLU_DIR="$2" MODULE_DIR="$1" MODID=vdbackup
  sh "$1/vdlu/update.sh" boot
' sh "$MODDIR" "$VDLU_DIR" "$VBINABI" >>"$VDLU_DIR/boot.log" 2>&1 &

exit 0
