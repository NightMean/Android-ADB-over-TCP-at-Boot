#!/system/bin/sh
ADB_TCP_PORT=5555
ADB_TCP_DESCRIPTION='Starts authenticated ADB over TCP at boot for Tailscale without Wi-Fi.'
ADB_TCP_DISABLED_KEY=adb_tcp_disabled

set_adb_tcp_status() {
  status_description="$(printf 'Status: %s | %s' "$1" "$ADB_TCP_DESCRIPTION")"
  if ! ksud module config set --temp override.description "$status_description"; then
    echo "WARNING: could not update KernelSU module status"
    return 1
  fi
}

adb_tcp_port_listening() {
  /system/bin/ss -ltn | /system/bin/grep -Eq ":$ADB_TCP_PORT([[:space:]]|$)"
}

adb_tcp_listener_active() {
  [ "$(/system/bin/getprop service.adb.tcp.port)" = "$ADB_TCP_PORT" ] &&
    [ "$(/system/bin/getprop init.svc.adbd)" = "running" ] &&
    adb_tcp_port_listening
}

adb_tcp_disabled_state() {
  module_config="$(ksud module config list 2>/dev/null)" || return 2
  printf '%s\n' "$module_config" | /system/bin/grep -qx "$ADB_TCP_DISABLED_KEY=true"
}

disable_adb_tcp_listener() {
  set_adb_tcp_status '⏳ ADB TCP Disabling'
  echo "$(/system/bin/date '+%F %T') disabling ADB TCP on port $ADB_TCP_PORT"
  /system/bin/setprop service.adb.tcp.port 0
  if [ "$(/system/bin/getprop service.adb.tcp.port)" != "0" ]; then
    set_adb_tcp_status '⚠️ ADB TCP Not Confirmed'
    echo "ERROR: could not clear service.adb.tcp.port"
    return 1
  fi

  /system/bin/stop adbd
  attempt=0
  while [ "$attempt" -lt 10 ]; do
    if ! adb_tcp_port_listening; then
      set_adb_tcp_status '⏸️ ADB TCP Disabled'
      echo "ADB TCP listener is disabled on port $ADB_TCP_PORT"
      return 0
    fi
    /system/bin/sleep 1
    attempt=$((attempt + 1))
  done

  set_adb_tcp_status '⚠️ ADB TCP Still Active'
  echo "ERROR: port $ADB_TCP_PORT is still listening"
  return 1
}

ensure_adb_tcp_listener() {
  if adb_tcp_listener_active; then
    set_adb_tcp_status '✅ ADB TCP Active'
    echo "ADB TCP listener is active on port $ADB_TCP_PORT"
    return 0
  fi

  set_adb_tcp_status '⏳ ADB TCP Starting'
  echo "$(/system/bin/date '+%F %T') starting ADB TCP listener"
  /system/bin/setprop service.adb.tcp.port "$ADB_TCP_PORT"
  if [ "$(/system/bin/getprop service.adb.tcp.port)" != "$ADB_TCP_PORT" ]; then
    set_adb_tcp_status '⚠️ ADB TCP Not Confirmed'
    echo "ERROR: could not set service.adb.tcp.port"
    return 1
  fi

  /system/bin/stop adbd
  /system/bin/start adbd
  attempt=0
  while [ "$attempt" -lt 20 ]; do
    if adb_tcp_listener_active; then
      set_adb_tcp_status '✅ ADB TCP Active'
      echo "ADB TCP listener is active on port $ADB_TCP_PORT"
      return 0
    fi
    /system/bin/sleep 1
    attempt=$((attempt + 1))
  done

  set_adb_tcp_status '⚠️ ADB TCP Not Confirmed'
  echo "ERROR: adbd did not listen on port $ADB_TCP_PORT"
  return 1
}
