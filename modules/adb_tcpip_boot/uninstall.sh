#!/system/bin/sh
/system/bin/setprop service.adb.tcp.port 0
/system/bin/stop adbd
/system/bin/start adbd