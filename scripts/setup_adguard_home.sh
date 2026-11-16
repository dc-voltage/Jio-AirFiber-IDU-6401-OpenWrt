#!/bin/sh
# ==============================================================================
# Jio AirFiber IDU-6401 - Automated AdGuard Home Setup Script
# Created by Boss DC VOLTAGE (https://github.com/dc-voltage)
# ==============================================================================

set -e

echo "=== [1/4] Installing AdGuard Home via apk ==="
apk add adguardhome luci-app-adguardhome

echo "=== [2/4] Moving dnsmasq to Port 54 to Free Port 53 for AdGuard Home ==="
uci set dhcp.@dnsmasq[0].port='54'
uci commit dhcp
/etc/init.d/dnsmasq restart

echo "=== [3/4] Enabling AdGuard Home Service ==="
/etc/init.d/adguardhome enable
/etc/init.d/adguardhome start

echo "=== [4/4] AdGuard Home Web Interface Ready! ==="
echo "Access the dashboard at http://192.168.5.1:3000"
echo "DNS server port: 53"
echo "Web portal port: 3000"
