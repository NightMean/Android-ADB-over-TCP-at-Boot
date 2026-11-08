#!/system/bin/sh
MODDIR=${MODDIR:-${0%/*}}
. "$MODDIR/adb_tcpip_common.sh" || exit 1

adb_tcp_disabled_state
config_status=$?
if [ "$config_status" -eq 0 ]; then
  if ! ksud module config delete "$ADB_TCP_DISABLED_KEY"; then
    echo "ERROR: could not save the enabled state"
    exit 1
  fi
  echo "Enabling ADB TCP. This can restart adbd and disconnect active ADB sessions."
  if ensure_adb_tcp_listener; then
    echo "ADB TCP is enabled. Tap Action again to disable it."
    exit 0
  fi
elif [ "$config_status" -eq 1 ]; then
  if ! ksud module config set "$ADB_TCP_DISABLED_KEY" true; then
    set_adb_tcp_status '⚠️ ADB TCP Not Confirmed'
    echo "ERROR: could not save the disabled state"
    exit 1
  fi
  echo "Disabling ADB TCP. Active ADB sessions will disconnect."
  if disable_adb_tcp_listener; then
    echo "ADB TCP is disabled and will stay off after reboot. Tap Action again to enable it."
    exit 0
  fi
else
  set_adb_tcp_status '⚠️ ADB TCP Not Confirmed'
  echo "ERROR: could not read the saved ADB TCP state"
  exit 1
fi
echo "The requested ADB TCP state could not be confirmed. See /data/local/tmp/adb-tcpip-boot.log after reboot."
exit 1
