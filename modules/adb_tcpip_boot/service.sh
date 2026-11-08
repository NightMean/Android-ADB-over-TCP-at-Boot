#!/system/bin/sh
MODDIR=${0%/*}
LOG=/data/local/tmp/adb-tcpip-boot.log
. "$MODDIR/adb_tcpip_common.sh" || exit 1
adb_tcp_disabled_state
config_status=$?
if [ "$config_status" -eq 0 ]; then
  disable_adb_tcp_listener > "$LOG" 2>&1
  exit $?
elif [ "$config_status" -gt 1 ]; then
  set_adb_tcp_status '⚠️ ADB TCP Not Confirmed'
  echo "ERROR: could not read the saved ADB TCP state" > "$LOG"
  exit 1
fi
ensure_adb_tcp_listener > "$LOG" 2>&1
