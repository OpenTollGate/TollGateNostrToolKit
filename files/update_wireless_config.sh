#!/bin/sh

# Check if both arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <SSID> <PASSWORD>"
    exit 1
fi

# Assign arguments to variables
NEW_SSID=$1
NEW_PASSWORD=$2

# Path to the wireless config file
CONFIG_FILE="/etc/config/wireless"

# Use awk to replace the SSID and PASSWORD
awk -v ssid="$NEW_SSID" -v pass="$NEW_PASSWORD" '
/config wifi-iface '"'"'wifinet1'"'"'/ {
    in_wifinet1 = 1
}
in_wifinet1 && /option ssid/ {
    $0 = "\toption ssid '"'"'" ssid "'"'"'"
}
in_wifinet1 && /option key/ {
    $0 = "\toption key '"'"'" pass "'"'"'"
}
/config / && !/config wifi-iface '"'"'wifinet1'"'"'/ {
    in_wifinet1 = 0
}
{print}
' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

# Check if the changes were made successfully
if [ $? -eq 0 ]; then
    echo "SSID and PASSWORD updated successfully."
    echo "New SSID: $NEW_SSID"
    echo "New PASSWORD: $NEW_PASSWORD"
else
    echo "Error: Failed to update the config file."
    exit 1
fi
