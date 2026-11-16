# Jio AirFiber IDU-6401 (JIDU6401) - Superpower OpenWrt 2026 Setup Guide

## 1. System Overview & Status
- **Device Model**: Jio AirFiber Indoor Unit (Sercomm JIDU6401 / MT7986A Filogic 830)
- **Firmware**: Official OpenWrt 25.12.6 (Linux Kernel 6.12.112 aarch64)
- **Storage**: Clean UBIFS overlay mounted with **~88 MB free space** (15% used)
- **Hardware Acceleration**: MediaTek Filogic PPE Hardware Flow Offloading enabled (multi-gigabit wire-speed routing at near 0% CPU)

---

## 2. Web Access & Credentials
| Portal | URL | Default Username | Default Password | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **OpenWrt LuCI Dashboard** | `http://192.168.5.1` | `root` | `Call@8848` | Router control panel, interfaces, firewall, wireless |
| **AdGuard Home Dashboard** | `http://192.168.5.1:3000` | `admin` | `Call@8848` | Ad blocking, DNS encryption, query logs |
| **SSH Terminal** | `192.168.5.1:22` | `root` | `Call@8848` | Command-line administration |

---

## 3. Physical Port Mapping (Dual-Zone Architecture)
| Port | Interface | Bridge | IP Subnet / Gateway | Internet Route |
| :--- | :--- | :--- | :--- | :--- |
| **WAN Port (Blue/WAN)** | `wan` | - | Dynamic (DHCP from Upstream) | Uplink to Internet |
| **LAN Port 1** | `lan1` | `br-lan` | `192.168.5.0/24` (GW: `192.168.5.1`) | **Direct Normal Internet** |
| **LAN Port 2** | `lan2` | `br-lan` | `192.168.5.0/24` (GW: `192.168.5.1`) | **Direct Normal Internet** |
| **LAN Port 3** | `lan3` | `br-lan` | `192.168.5.0/24` (GW: `192.168.5.1`) | **Direct Normal Internet** |
| **LAN Port 4** | `lan4` | `br-vpn` | `192.168.40.0/24` (GW: `192.168.40.1`) | **100% Dedicated VPN (Kill-Switch Active)** |

> [!IMPORTANT]
> **Hardware Isolation & Kill-Switch**:
> LAN Port 4 is in its own isolated hardware bridge (`br-vpn`) and firewall zone (`vpn`). Traffic entering Port 4 or the VPN Wi-Fi networks **CANNOT** leak to the normal WAN. If your VPN is down or unconfigured, traffic is dropped completely.

---

## 4. Wi-Fi 6 Configuration (4x4 MU-MIMO, 160MHz)
Default Wi-Fi Password for all networks: **`AirFiber@2026`** (Security: WPA2/WPA3 Personal Mixed).

| Wi-Fi SSID | Band | Network Zone | Routing Behavior |
| :--- | :--- | :--- | :--- |
| **`JioAirFiber_2.4G`** | 2.4 GHz | Normal (`lan`) | Direct Normal High-Speed Internet |
| **`JioAirFiber_5G`** | 5 GHz (160MHz) | Normal (`lan`) | Direct Ultra-Fast Wi-Fi 6 Internet |
| **`JioAirFiber_VPN_2.4G`** | 2.4 GHz | VPN (`vpn`) | Dedicated VPN Tunnel (Kill-Switch Active) |
| **`JioAirFiber_VPN_5G`** | 5 GHz (160MHz) | VPN (`vpn`) | Dedicated VPN Tunnel (Kill-Switch Active) |

---

## 5. AdGuard Home (Network-wide AdBlocker)
- **Status**: Running as a background daemon.
- **Port**: Web UI on port `3000` (`http://192.168.1.1:3000`).
- **Setup**: Open `http://192.168.1.1:3000` in your browser. Port 53 is already freed and reserved for AdGuard Home. Follow the short setup wizard to set your admin credentials.

---

## 6. WireGuard VPN Status & Configuration
- **Active Provider**: Official ProtonVPN USA (Server: `US-FREE#3`)
- **Status**: **ONLINE & CONNECTED** (`loc=US`, Active handshake)
- **Public VPN IP**: `195.181.163.32` (United States IP address)
- **Endpoint**: `195.181.163.1:51820`
- **Interface**: `wg0`
- **Routing Rules**:
  - All clients connected to **LAN Port 4** or **`JioAirFiber_VPN_*`** Wi-Fi are automatically routed through `wg0` directly to the USA.
  - **Hardware Kill-Switch**: Active (If VPN drops, no unencrypted traffic leaks to your real ISP).

---

## 7. LED Configuration & Aesthetics
- **Status LED Profile**: **Heartbeat Pulse (Blue)**
  - Behavior: Pulses like a heartbeat (`thump-thump`), dynamically reflecting CPU activity.
  - Red & Green Status LEDs: Disabled / OFF for a clean, non-distracting futuristic aesthetic.
  - Persistent: Saved permanently in `/etc/config/system` (retains after reboots).
  - Can be customized anytime via LuCI: **System** -> **LED Configuration**.

---

## 8. Factory Backups
Full binary partition backups are safely stored in:
`/home/dc/Documents/IDU-6401/backups/`
- `Factory.bin` (Wi-Fi calibration / EEPROM)
- `BL2.bin` (Bootloader Stage 2)
- `FIP.bin` (ATF + U-Boot)
- `uboot-env.bin` (U-Boot environment variables)
- `MFG.bin` (Sercomm manufacturing data)
- `Jio-Reserved.bin` (Factory encryption keys)
- **U-Boot Bootpass**: `!&X@oSCLY5tpz)=<`
