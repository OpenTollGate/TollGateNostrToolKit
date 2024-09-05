#!/bin/sh

# Check if both arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <SSID> <PASSWORD>"
    exit 1
fi

# Assign arguments to variables
NEW_SSID=$1
NEW_PASSWORD=$2

# Remove existing wifinet1 configuration if it exists
uci delete wireless.@wifi-iface[1]

# Create a new wifi-iface section named 'wifinet1'
uci add wireless wifi-iface
uci set wireless.@wifi-iface[-1]=wifi-iface
uci set wireless.@wifi-iface[-1].name='wifinet1'

# Set the options for the new wifi-iface
uci set wireless.@wifi-iface[-1].device='radio0'
uci set wireless.@wifi-iface[-1].mode='sta'
uci set wireless.@wifi-iface[-1].network='wwan'
uci set wireless.@wifi-iface[-1].ssid="$NEW_SSID"
uci set wireless.@wifi-iface[-1].encryption='sae'
uci set wireless.@wifi-iface[-1].key="$NEW_PASSWORD"

# Commit the changes
uci commit wireless

# Restart the network to apply changes
/etc/init.d/network restart

# Check if the changes were made successfully
if [ $? -eq 0 ]; then
    echo "SSID and PASSWORD updated successfully."
    echo "New SSID: $NEW_SSID"
    echo "New PASSWORD: $NEW_PASSWORD"
else
    echo "Error: Failed to update the wireless configuration."
    exit 1
fi

