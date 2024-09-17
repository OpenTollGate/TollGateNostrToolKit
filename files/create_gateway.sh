#!/bin/sh

# Check if both arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <SSID> <PASSWORD>"
    exit 1
fi

# Assign arguments to variables
NEW_SSID=$1
NEW_PASSWORD=$2

# Update firewall configuration
uci set firewall.@zone[1].network='wan wan6 wwan'

# Update network configuration
uci set network.wwan=interface
uci set network.wwan.proto='dhcp'

# Update wireless configuration
uci set wireless.radio0.disabled='0'
uci set wireless.radio0.cell_density='0'
uci set wireless.default_radio0.disabled='1'

# Remove existing wifinet1 configuration if it exists
uci delete wireless.wifinet1

# Create a new wifi-iface section named 'wifinet1'
uci set wireless.wifinet1=wifi-iface
uci set wireless.wifinet1.device='radio0'
uci set wireless.wifinet1.mode='sta'
uci set wireless.wifinet1.network='wwan'
uci set wireless.wifinet1.ssid="$NEW_SSID"
uci set wireless.wifinet1.encryption='sae'
uci set wireless.wifinet1.key="$NEW_PASSWORD"

# Commit the changes
uci commit firewall
uci commit network
uci commit wireless

# Restart the network to apply changes
/etc/init.d/network restart

# Check if the changes were made successfully
if [ $? -eq 0 ]; then
    echo "Wireless configuration updated successfully."
    echo "New SSID: $NEW_SSID"
    echo "New PASSWORD: $NEW_PASSWORD"
else
    echo "Error: Failed to update the wireless configuration."
    exit 1
fi
