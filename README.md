<div align="center">
  <h1>Android ADB over TCP at Boot</h1>
</div>

<div align="center">
  <a href="https://github.com/NightMean/Android-ADB-over-TCP-at-Boot/releases/latest"><img alt="GitHub Release" src="https://img.shields.io/github/v/release/NightMean/Android-ADB-over-TCP-at-Boot?style=flat"></a>
  <a href="https://github.com/NightMean/Android-ADB-over-TCP-at-Boot/releases/latest"><img alt="Downloads" src="https://img.shields.io/github/downloads/NightMean/Android-ADB-over-TCP-at-Boot/total?style=flat"></a>
  <a href="https://github.com/NightMean/Android-ADB-over-TCP-at-Boot/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/github/license/NightMean/Android-ADB-over-TCP-at-Boot?style=flat"></a>
</div>

<p align="center"><strong>Remote phone access over a VPN such as Tailscale on mobile data, with Wi-Fi off. Useful for remote phone troubleshooting with an LLM.</strong></p>

<hr>

## Overview

At boot, this module starts Android Debug Bridge (ADB) over TCP on port 5555.
An ADB client can connect whenever it has a network route to the phone,
including over mobile data when Wi-Fi is off.

> [!NOTE]
> To reach the phone remotely, install and configure a VPN such as
> [Tailscale](https://tailscale.com/). This module does not install or
> configure the VPN.

## Requirements

- A **rooted** Android device running [KernelSU v3.0.0 or later](https://github.com/tiann/KernelSU).

## Compatibility

Tested on a Nothing Phone (2a) running Android 16. Other devices and Android
versions have not been verified.

## Install

1. Download the latest
   [module ZIP from Releases](https://github.com/NightMean/Android-ADB-over-TCP-at-Boot/releases/latest).
2. In KernelSU Manager, choose **Modules → Install from storage**, select the
   ZIP, then reboot.

> [!NOTE]
> The module's **Action** button turns its TCP listener off or on without
> disabling the module. The selected state persists across reboots.

## Connect for the first time

> [!IMPORTANT]
> Run `adb connect PHONE_VPN_IP:5555` from an ADB client that can reach the
> phone. If this computer has not been authorized before, unlock the phone and
> approve its **Allow USB debugging?** prompt. Select **Always allow from this
> computer** if you want to save its key. You do not need a USB cable; you can
> approve the first connection over the VPN. Authorize each ADB client you use.

## Verify

After reboot, check the module card in KernelSU Manager. From an ADB client that
can reach the phone over your VPN, run:

~~~sh
adb -s PHONE_VPN_IP:5555 get-state
adb -s PHONE_VPN_IP:5555 shell getprop ro.product.model
~~~

Replace PHONE_VPN_IP with an IP address that your VPN can use to reach the
phone. A successful connection reports device and the expected model. If ADB
shows the device as unauthorized, approve the prompt on the phone and connect
again.

## Recovery and logs

The module description shows the listener state. Toggling can disconnect
active ADB sessions. This controls the module's TCP listener on port 5555;
USB debugging and Android Wireless debugging are separate settings.

The boot log is at `/data/local/tmp/adb-tcpip-boot.log`. The uninstall script
clears the TCP port property and restarts adbd.

## Security

> [!WARNING]
> This module keeps ADB listening on TCP port 5555 after boot. Android's ADB
> listener accepts connections on all network interfaces, so any device with a
> network route to the phone can try to connect. On standard secure Android
> builds, ADB key authorization limits access to computers you approve, but it
> does not hide or filter the open port. Keep access behind a VPN with rules
> that allow only trusted devices. Never expose port 5555 to the public
> Internet or forward it from a router.

## References

The setup and use case were inspired by
[pueblokc/android-remote-adb-tailscale](https://github.com/pueblokc/android-remote-adb-tailscale)
and the article
[I Handed My AI the Keys to My Android Phones](https://errorzap.com/posts/letting-my-ai-drive-my-android-phones/).
The original repository uses Tasker and Termux:Boot scripts; this module does
not include them.

## Donations

<div align="center"><a href="https://github.com/sponsors/NightMean"><img alt="Sponsor" src="https://img.shields.io/badge/Sponsor-ea4aaa?style=for-the-badge&logo=githubsponsors&logoColor=white" /></a>&nbsp;<a href="https://www.buymeacoffee.com/nightmean"><img alt="Buy Me a Coffee" src="https://img.shields.io/badge/Buy_Me_a_Coffee-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=black" /></a>&nbsp;<a href="https://ko-fi.com/nightmean"><img alt="Ko-fi" src="https://img.shields.io/badge/Ko--fi-FF5E5B?style=for-the-badge&logo=kofi&logoColor=white" /></a></div>

## License

This project is licensed under the [MIT License](https://github.com/NightMean/Android-ADB-over-TCP-at-Boot/blob/main/LICENSE).
