#!/bin/sh

# Activate TollGate configuration

# Check if an argument is provided
if [ -n "$1" ]; then
    # If argument is provided, set SSID to 'TollGate_argument'
    NEW_SSID="TollGate_$1"
else
    # If no argument, set SSID to 'TollGate'
    NEW_SSID="TollGate"
fi

# Change SSID to the new value
uci set wireless.default_radio0.ssid="$NEW_SSID"

# Remove the 'disabled' option
uci delete wireless.default_radio0.disabled

# Commit the changes
uci commit wireless

# Restart the wireless service
wifi reload

echo "TollGate activated. SSID changed to '$NEW_SSID' and AP enabled."
