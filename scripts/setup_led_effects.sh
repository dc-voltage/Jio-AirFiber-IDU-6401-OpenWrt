#!/bin/sh
# ==============================================================================
# Jio AirFiber IDU-6401 - LED Customizer Script
# Created by Boss DC VOLTAGE (https://github.com/dc-voltage)
# Usage: ./setup_led_effects.sh [heartbeat|traffic|stealth|reset]
# ==============================================================================

MODE="${1:-heartbeat}"

# Clear previous settings
while uci -q delete system.@led[0]; do :; done

case "$MODE" in
    heartbeat)
        echo "Configuring Futuristic Heartbeat Pulse (Blue LED)..."
        uci add system led
        uci set system.@led[-1].name='Blue Heartbeat'
        uci set system.@led[-1].sysfs='blue:status'
        uci set system.@led[-1].trigger='heartbeat'

        uci add system led
        uci set system.@led[-1].name='Red Off'
        uci set system.@led[-1].sysfs='red:status'
        uci set system.@led[-1].trigger='none'
        uci set system.@led[-1].default='0'

        uci add system led
        uci set system.@led[-1].name='Green Off'
        uci set system.@led[-1].sysfs='green:status'
        uci set system.@led[-1].trigger='none'
        uci set system.@led[-1].default='0'
        ;;

    traffic)
        echo "Configuring Internet Traffic Activity Blink (Green LED)..."
        uci add system led
        uci set system.@led[-1].name='Green WAN Activity'
        uci set system.@led[-1].sysfs='green:status'
        uci set system.@led[-1].trigger='netdev'
        uci set system.@led[-1].dev='wan'
        uci set system.@led[-1].mode='link rx tx'

        uci add system led
        uci set system.@led[-1].name='Red Off'
        uci set system.@led[-1].sysfs='red:status'
        uci set system.@led[-1].trigger='none'
        uci set system.@led[-1].default='0'

        uci add system led
        uci set system.@led[-1].name='Blue Off'
        uci set system.@led[-1].sysfs='blue:status'
        uci set system.@led[-1].trigger='none'
        uci set system.@led[-1].default='0'
        ;;

    stealth)
        echo "Configuring Night Stealth Mode (All LEDs OFF)..."
        uci add system led
        uci set system.@led[-1].name='Red Off'
        uci set system.@led[-1].sysfs='red:status'
        uci set system.@led[-1].trigger='none'
        uci set system.@led[-1].default='0'

        uci add system led
        uci set system.@led[-1].name='Green Off'
        uci set system.@led[-1].sysfs='green:status'
        uci set system.@led[-1].trigger='none'
        uci set system.@led[-1].default='0'

        uci add system led
        uci set system.@led[-1].name='Blue Off'
        uci set system.@led[-1].sysfs='blue:status'
        uci set system.@led[-1].trigger='none'
        uci set system.@led[-1].default='0'
        ;;

    *)
        echo "Usage: $0 [heartbeat|traffic|stealth]"
        exit 1
        ;;
esac

uci commit system
/etc/init.d/led restart
echo "LED profile applied successfully!"
