# Jio AirFiber IDU-6401 (Sercomm JIDU6401) — Ultimate Superpower OpenWrt 2026 Guide

[![OpenWrt Version](https://img.shields.io/badge/OpenWrt-25.12.6%20(Kernel%206.12)-blue.svg?style=for-the-badge&logo=openwrt)](https://openwrt.org/)
[![Hardware](https://img.shields.io/badge/Hardware-MediaTek%20Filogic%20830%20(MT7986A)-red.svg?style=for-the-badge)](https://www.mediatek.com/)
[![Wi-Fi Standard](https://img.shields.io/badge/Wi--Fi%206-AX6000%204x4%20160MHz-green.svg?style=for-the-badge)](https://openwrt.org/)
[![Status](https://img.shields.io/badge/Status-100%25%20Tested%20%26%20Verified-brightgreen.svg?style=for-the-badge)](#)

> **Complete Step-by-Step Guide** to unlocking the **Jio AirFiber Indoor Unit (Sercomm JIDU6401 / IDU-6401)**, flashing permanent Official OpenWrt, configuring **Dual-Zone Hardware VPN Routing (Isolated LAN Port 4 + Dedicated VPN Wi-Fi with Kill-Switch)**, installing **AdGuard Home**, and enabling futuristic **RGB LED effects**.
>
> Developed & Tested by **Boss DC VOLTAGE** ([GitHub](https://github.com/dc-voltage)) in collaboration with the Jio/Airtel Unlock Community.

---

## 📑 Table of Contents
1. [Hardware Specifications](#-hardware-specifications)
2. [Why Flash OpenWrt? (Stock vs OpenWrt)](#-why-flash-openwrt-stock-vs-openwrt)
3. [Step 1: Critical Factory MTD Partition Backups](#-step-1-critical-factory-mtd-partition-backups)
4. [Step 2: U-Boot Signature Bypass & Bootpass](#-step-2-u-boot-signature-bypass--bootpass)
5. [Step 3: Flashing OpenWrt (Initramfs & Sysupgrade)](#-step-3-flashing-openwrt-initramfs--sysupgrade)
6. [Step 4: Dual-Zone Network & Dedicated VPN Setup](#-step-4-dual-zone-network--dedicated-vpn-setup)
7. [Step 5: Network-Wide AdGuard Home AdBlocker](#-step-5-network-wide-adguard-home-adblocker)
8. [Step 6: WireGuard VPN (ProtonVPN / Cloudflare WARP)](#-step-6-wireguard-vpn-protonvpn--cloudflare-warp)
9. [Step 7: Futuristic RGB LED Effects](#-step-7-futuristic-rgb-led-effects)
10. [Troubleshooting & Common Pitfalls](#-troubleshooting--common-pitfalls)

---

## ⚡ Hardware Specifications

| Component | Specification |
| :--- | :--- |
| **Model** | Jio AirFiber IDU-6401 / Sercomm JIDU6401 (JIDU6J01) |
| **SoC** | MediaTek MT7986A (Filogic 830) Quad-Core ARM Cortex-A53 @ 2.0 GHz |
| **Hardware Packet Engine** | MediaTek PPE Hardware Flow Offloading (Multi-Gigabit Line-Rate Routing) |
| **RAM** | 512 MB DDR4 High-Speed RAM |
| **Storage** | 256 MB SPI-NAND Flash (UBIFS with **~104 MB writable `/overlay`**) |
| **Wi-Fi 6 (2.4 GHz)** | MT7975N / MT7986 4x4 MU-MIMO (HE40, up to 1148 Mbps) |
| **Wi-Fi 6 (5 GHz)** | MT7976C / MT7986 4x4 MU-MIMO 160MHz (HE160 / HE80, up to 4804 Mbps) |
| **Switch Architecture** | MediaTek DSA Switch (Independent `lan1`, `lan2`, `lan3`, `lan4`, `wan`) |
| **LED Indicators** | Status RGB (Red, Green, Blue) + Wireless Activity LEDs |

---

## 🆚 Why Flash OpenWrt? (Stock vs OpenWrt)

| Feature | Stock Jio Firmware | Superpower OpenWrt 2026 |
| :--- | :--- | :--- |
| **Usable Free Storage** | ~5.7 MB (Constantly full) | **~104.0 MB Free** (UBIFS Overlay) |
| **TR-069 ACS Tracking** | Locked to Jio Cloud, remote wipe active | **100% Eradicated** (Zero ISP backdoors) |
| **Physical Port Isolation** | None (All LAN ports bridged together) | **Hardware Dual-Zone (Port 4 isolated to VPN)** |
| **Wi-Fi Networks** | Single Jio SSID with limited controls | **4 Simultaneous VAP SSIDs (Normal + VPN)** |
| **Ad Blocking** | Not supported | **AdGuard Home built-in** (Blocks all ads & tracking) |
| **VPN Support** | None | **WireGuard with Hardware Kill-Switch** |
| **Flow Offloading** | Software / ISP throttled | **MediaTek PPE Hardware Accelerated** (0% CPU) |

---

## 🛡️ Step 1: Critical Factory MTD Partition Backups

> [!CAUTION]
> **NEVER flash any firmware without backing up your device's unique Factory partition!**
> The `Factory` partition contains unique RF calibration tables (EEPROM) and MAC addresses. Without it, Wi-Fi performance will be permanently crippled.

Connect via SSH to your stock router root shell and run:

```bash
mkdir -p /tmp/backups
# 1. Wi-Fi Calibration / EEPROM (CRITICAL)
nanddump -f /tmp/backups/Factory.bin /dev/mtd4

# 2. Bootloader Stage 2
nanddump -f /tmp/backups/BL2.bin /dev/mtd1

# 3. ATF + U-Boot
nanddump -f /tmp/backups/FIP.bin /dev/mtd5

# 4. U-Boot Environment
nanddump -f /tmp/backups/uboot-env.bin /dev/mtd2

# 5. Sercomm Manufacturing Data
nanddump -f /tmp/backups/MFG.bin /dev/mtd3

# 6. Jio Reserved Factory Keys
nanddump -f /tmp/backups/Jio-Reserved.bin /dev/mtd10
```

Download all 6 `.bin` files to your PC using SCP:
```bash
scp -O root@192.168.31.1:/tmp/backups/*.bin ./backups/
```
*(Or simply execute `./scripts/backup_factory_mtd.sh`)*.

---

## 🔑 Step 2: U-Boot Signature Bypass & Bootpass

The stock Sercomm U-Boot uses signed image verification. To boot generic unsigned OpenWrt kernels without hardware modification:

1. **U-Boot Console Bootpass**:
   ```text
   !&X@oSCLY5tpz)=<
   ```
2. **Signature Enforcement Bypass**:
   In U-Boot, execute:
   ```text
   fw_setenv bootcmd "ubi detach; ubi part ubi2; ubi read 46000000 kernel; fdt addr \$(fdtcontroladdr); fdt rm /signature; bootm 0x46000000"
   fw_setenv dual_boot.current_slot 1
   fw_setenv dual_boot.slot_0_invalid 1
   fw_setenv dual_boot.slot_1_invalid 1
   ```

---

## 🚀 Step 3: Flashing OpenWrt (Initramfs & Sysupgrade)

1. Write the verified OpenWrt initramfs factory UBI to `/dev/mtd6` (`ubi2`):
   ```bash
   ubidetach -d 2 2>/dev/null || true
   ubiformat /dev/mtd6 -y -f /tmp/openwrt-initramfs-factory.ubi
   reboot
   ```
2. Once the router reboots into OpenWrt RAM mode (`192.168.1.1`):
   ```bash
   scp sysupgrade.bin root@192.168.1.1:/tmp/sysupgrade.bin
   ssh root@192.168.1.1 "sysupgrade -n /tmp/sysupgrade.bin"
   ```
3. After reboot, permanent OpenWrt is online at **`http://192.168.1.1`**!

---

## 🌐 Step 4: Dual-Zone Network & Dedicated VPN Setup

This architecture completely isolates **LAN Port 4** and broadcasts dedicated **VPN Wi-Fi SSIDs**.

```
                           ┌───────────────────────────┐
                           │   Jio AirFiber IDU-6401   │
                           └─────────────┬─────────────┘
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 │                                               │
        ┌────────┴────────┐                             ┌────────┴────────┐
        │  Zone 1: Normal │                             │   Zone 2: VPN   │
        │   Direct ISP    │                             │ WireGuard Tunnel│
        ├─────────────────┤                             ├─────────────────┤
        │ • LAN Ports 1-3 │                             │ • LAN Port 4    │
        │ • JioAirFiber_2G│                             │ • JioAirFiber_  │
        │ • JioAirFiber_5G│                             │   VPN_2.4G & 5G │
        │ • Subnet:       │                             │ • Subnet:       │
        │   192.168.5.0/24│                             │   192.168.40.0/ │
        │ • Full Line-Rate│                             │ • KILL-SWITCH   │
        └─────────────────┘                             └─────────────────┘
```

Run the automated setup script on the router:
```bash
sh /tmp/setup_dual_zone_vpn.sh
```

### Key Capabilities:
* **LAN Port 4 Hardware Isolation**: Assigned to bridge `br-vpn` (`192.168.40.1`).
* **Dedicated SSIDs**:
  * `JioAirFiber_2.4G` & `JioAirFiber_5G` (Normal Direct Internet)
  * `JioAirFiber_VPN_2.4G` & `JioAirFiber_VPN_5G` (Dedicated VPN Tunnel)
  * Default Wi-Fi Password: `AirFiber@2026`
* **Hardware Kill-Switch**: If WireGuard disconnects, kernel routing rules `prohibit` drop all traffic from `192.168.40.0/24`. Zero unencrypted leaks to your ISP!

---

## 🛡️ Step 5: Network-Wide AdGuard Home AdBlocker

1. Run the automated AdGuard Home installer:
   ```bash
   sh /tmp/setup_adguard_home.sh
   ```
2. Open the AdGuard Home Web UI at **`http://192.168.5.1:3000`**.
3. **Features Configured**:
   * DNS listening on port `53`.
   * Internal `dnsmasq` moved to port `54` with local reverse PTR lookup (`.lan`).
   * Encrypted Upstream DoH: Cloudflare (`https://dns.cloudflare.com/dns-query`), Google, and Quad9.
   * **16 MB Optimistic RAM Caching**: Serves recurring queries in **0 ms**!
   * Pre-loaded filters: AdGuard DNS Filter, AdAway, and OISD Big.

---

## 🔒 Step 6: WireGuard VPN (ProtonVPN / Cloudflare WARP)

### Using ProtonVPN:
1. Log in to [account.protonvpn.com](https://account.protonvpn.com) -> **Downloads** -> **WireGuard configuration**.
2. Select **Router** -> Country: **United States** -> Click **Create**.
3. Download the `.conf` file and note the `PrivateKey`, `Address`, `PublicKey`, and `Endpoint`.
4. Apply to router:
   ```bash
   uci set network.wg0.private_key='<YOUR_PRIVATE_KEY>'
   uci -q delete network.wg0.addresses
   uci add_list network.wg0.addresses='10.2.0.2/32'

   uci -q delete network.@wireguard_wg0[0]
   uci add network wireguard_wg0
   uci set network.@wireguard_wg0[-1].public_key='<PROTON_PUBLIC_KEY>'
   uci set network.@wireguard_wg0[-1].endpoint_host='<PROTON_IP>'
   uci set network.@wireguard_wg0[-1].endpoint_port='51820'
   uci add_list network.@wireguard_wg0[-1].allowed_ips='0.0.0.0/0'
   uci set network.@wireguard_wg0[-1].persistent_keepalive='25'
   uci set network.@wireguard_wg0[-1].route_allowed_ips='0'

   uci commit network && /etc/init.d/network reload
   ```
5. All devices on **LAN Port 4** and **`JioAirFiber_VPN_*`** will immediately route through the USA with public IP `195.181.x.x`!

---

## 💡 Step 7: Futuristic RGB LED Effects

Configure the front-panel status LED using `./scripts/setup_led_effects.sh`:

```bash
# 1. Futuristic Heartbeat Pulse (Blue LED pulses with CPU load)
./scripts/setup_led_effects.sh heartbeat

# 2. Network Activity Blink (Green LED blinks with real-time download/upload)
./scripts/setup_led_effects.sh traffic

# 3. Night Stealth Mode (All LEDs completely turned OFF)
./scripts/setup_led_effects.sh stealth
```

---

## 🛠️ Troubleshooting & Common Pitfalls

### 1. "No Internet Connection" on Android / iOS when connecting to VPN Wi-Fi
* **Cause**: Two common issues:
  1. Router table 100 did not have a return route for the local subnet, routing local DNS replies to the VPN tunnel.
  2. Missing DHCP Option 6.
* **Fix**:
  Ensure the following rules are present in `/etc/config/network`:
  ```uci
  uci set network.vpn_local_rule=rule
  uci set network.vpn_local_rule.dest='192.168.40.0/24'
  uci set network.vpn_local_rule.lookup='main'
  uci set network.vpn_local_rule.priority='90'

  uci add_list dhcp.vpn.dhcp_option='6,192.168.40.1'
  uci add_list dhcp.vpn.dhcp_option='3,192.168.40.1'
  ```

### 2. HTTPS Webpages Hang or Load Slowly over VPN
* **Cause**: PMTU blackhole / TCP fragmentation over WireGuard tunnel.
* **Fix**:
  Enable TCP MSS Clamping on zone `vpn` and set WireGuard MTU:
  ```uci
  uci set network.wg0.mtu='1360'
  uci set firewall.vpn.mtu_fix='1'
  uci commit && /etc/init.d/firewall reload
  ```

### 3. 5GHz Radio Fails to Transmit (`DFS start_dfs_cac() failed`)
* **Cause**: Setting 160MHz width on Channel 36 overlaps with DFS radar channels 52-64.
* **Fix**: Set channel 36 to `HE80` (80MHz width, 1201 Mbps). Channels 36-48 are UNII-1 non-DFS and broadcast instantly.

---

## 🤝 Credits & Community
* **Boss DC VOLTAGE**: Lead Reverse Engineer & Guide Author ([GitHub](https://github.com/dc-voltage))
* **JFC-Group**: Jio/Airtel Research & Method Repository ([GitHub](https://github.com/JFC-Group))
* **OpenWrt Project**: For the incredible open-source embedded Linux ecosystem.

---
*Disclaimer: This repository is intended strictly for educational and network engineering purposes. Flashing custom firmware is performed at your own risk.*
