#!/bin/sh

# Deactivate TollGate configuration

# Change SSID back to 'OpenWrt'
uci set wireless.default_radio0.ssid='OpenWrt'

# Disable the AP
uci set wireless.default_radio0.disabled='1'

# Commit the changes
uci commit wireless

# Restart the wireless service
wifi reload

echo "TollGate deactivated. SSID changed back to 'OpenWrt' and AP disabled."
