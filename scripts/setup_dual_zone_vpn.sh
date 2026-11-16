#!/bin/sh
# ==============================================================================
# Jio AirFiber IDU-6401 - Dual-Zone VPN Setup Script (LAN Port 4 + VPN Wi-Fi)
# Created by Boss DC VOLTAGE (https://github.com/dc-voltage)
# ==============================================================================

set -e

echo "=== [1/6] Configuring Dedicated VPN Bridge & Isolating LAN Port 4 ==="
# Remove lan4 from normal bridge br-lan
uci -q del_list network.@device[0].ports='lan4'

# Create dedicated bridge br-vpn with lan4
uci -q delete network.br_vpn
uci set network.br_vpn=device
uci set network.br_vpn.name='br-vpn'
uci set network.br_vpn.type='bridge'
uci add_list network.br_vpn.ports='lan4'

# Create static interface vpn
uci -q delete network.vpn
uci set network.vpn=interface
uci set network.vpn.device='br-vpn'
uci set network.vpn.proto='static'
uci set network.vpn.ipaddr='192.168.40.1'
uci set network.vpn.netmask='255.255.255.0'

echo "=== [2/6] Configuring DHCP Server for VPN Subnet (192.168.40.0/24) ==="
uci -q delete dhcp.vpn
uci set dhcp.vpn=dhcp
uci set dhcp.vpn.interface='vpn'
uci set dhcp.vpn.start='100'
uci set dhcp.vpn.limit='150'
uci set dhcp.vpn.leasetime='12h'
uci add_list dhcp.vpn.dhcp_option='3,192.168.40.1'
uci add_list dhcp.vpn.dhcp_option='6,192.168.40.1'
uci set dhcp.vpn.ra='disabled'
uci set dhcp.vpn.dhcpv6='disabled'

echo "=== [3/6] Configuring Dedicated VPN Wi-Fi 6 Networks (2.4G & 5G) ==="
# 2.4GHz VPN Wi-Fi
uci -q delete wireless.vpn_radio0
uci set wireless.vpn_radio0=wifi-iface
uci set wireless.vpn_radio0.device='radio0'
uci set wireless.vpn_radio0.ssid='JioAirFiber_VPN_2.4G'
uci set wireless.vpn_radio0.network='vpn'
uci set wireless.vpn_radio0.mode='ap'
uci set wireless.vpn_radio0.encryption='sae-mixed'
uci set wireless.vpn_radio0.key='AirFiber@2026'
uci set wireless.vpn_radio0.disabled='0'

# 5GHz VPN Wi-Fi
uci -q delete wireless.vpn_radio1
uci set wireless.vpn_radio1=wifi-iface
uci set wireless.vpn_radio1.device='radio1'
uci set wireless.vpn_radio1.ssid='JioAirFiber_VPN_5G'
uci set wireless.vpn_radio1.network='vpn'
uci set wireless.vpn_radio1.mode='ap'
uci set wireless.vpn_radio1.encryption='sae-mixed'
uci set wireless.vpn_radio1.key='AirFiber@2026'
uci set wireless.vpn_radio1.disabled='0'

echo "=== [4/6] Setting up Policy Routing Table & Hardware Kill-Switch ==="
grep -q '100 vpn' /etc/iproute2/rt_tables 2>/dev/null || echo '100 vpn' >> /etc/iproute2/rt_tables

# Default route via WireGuard table 100
uci -q delete network.wg0_route
uci set network.wg0_route=route
uci set network.wg0_route.interface='wg0'
uci set network.wg0_route.target='0.0.0.0/0'
uci set network.wg0_route.table='100'

# Local subnet return route for DNS replies
uci -q delete network.vpn_connected_route
uci set network.vpn_connected_route=route
uci set network.vpn_connected_route.interface='vpn'
uci set network.vpn_connected_route.target='192.168.40.0/24'
uci set network.vpn_connected_route.table='100'

# Policy rules
uci -q delete network.vpn_local_rule
uci set network.vpn_local_rule=rule
uci set network.vpn_local_rule.dest='192.168.40.0/24'
uci set network.vpn_local_rule.lookup='main'
uci set network.vpn_local_rule.priority='90'

uci -q delete network.vpn_subnet_rule
uci set network.vpn_subnet_rule=rule
uci set network.vpn_subnet_rule.src='192.168.40.0/24'
uci set network.vpn_subnet_rule.lookup='100'
uci set network.vpn_subnet_rule.priority='99'

uci -q delete network.vpn_rule
uci set network.vpn_rule=rule
uci set network.vpn_rule.in='vpn'
uci set network.vpn_rule.lookup='100'
uci set network.vpn_rule.priority='100'

# Hardware Kill-Switch rules (Drop traffic if VPN is down)
uci -q delete network.vpn_killswitch
uci set network.vpn_killswitch=rule
uci set network.vpn_killswitch.in='vpn'
uci set network.vpn_killswitch.action='prohibit'
uci set network.vpn_killswitch.priority='101'

uci -q delete network.vpn_subnet_killswitch
uci set network.vpn_subnet_killswitch=rule
uci set network.vpn_subnet_killswitch.src='192.168.40.0/24'
uci set network.vpn_subnet_killswitch.action='prohibit'
uci set network.vpn_subnet_killswitch.priority='102'

echo "=== [5/6] Configuring Firewall Zones & Clamping TCP MTU ==="
uci -q delete network.wg0
uci set network.wg0=interface
uci set network.wg0.proto='wireguard'
uci set network.wg0.mtu='1360'

# Zone: vpn
uci add firewall zone
uci set firewall.@zone[-1].name='vpn'
uci add_list firewall.@zone[-1].network='vpn'
uci set firewall.@zone[-1].input='ACCEPT'
uci set firewall.@zone[-1].output='ACCEPT'
uci set firewall.@zone[-1].forward='REJECT'
uci set firewall.@zone[-1].mtu_fix='1'

# Zone: wg_zone (Outbound WireGuard)
uci add firewall zone
uci set firewall.@zone[-1].name='wg_zone'
uci add_list firewall.@zone[-1].network='wg0'
uci set firewall.@zone[-1].input='REJECT'
uci set firewall.@zone[-1].output='ACCEPT'
uci set firewall.@zone[-1].forward='REJECT'
uci set firewall.@zone[-1].masq='1'
uci set firewall.@zone[-1].mtu_fix='1'

# Forwarding rule: vpn -> wg_zone ONLY (Zero leak to WAN)
uci add firewall forwarding
uci set firewall.@forwarding[-1].src='vpn'
uci set firewall.@forwarding[-1].dest='wg_zone'

echo "=== [6/6] Committing changes & Reloading Services ==="
uci commit network
uci commit wireless
uci commit firewall
uci commit dhcp

/etc/init.d/firewall reload
/etc/init.d/dnsmasq restart
/etc/init.d/network reload
wifi reload

echo ""
echo "Dual-Zone VPN Setup Complete! Connect to JioAirFiber_VPN_* or LAN Port 4."
