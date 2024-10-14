#!/bin/sh

# Check if both arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <SSID> <PASSWORD>"
    exit 1
fi

# Assign arguments to variables
NEW_SSID=$1
NEW_PASSWORD=$2

get_wifi_interface() {
    # This will get the first managed mode interface
    iw dev | awk '$1 == "Interface" {iface=$2} $1 == "type" && $2 == "managed" {print iface; exit}'
}

# Function to determine encryption type
get_encryption_type() {
    local ssid="$1"
    local interface=get_wifi_interface

    # Ensure the interface is up
    ip link set $interface up

    # Use iw to scan for networks and grep for the specific SSID
    encryption=$(iw dev $interface scan | awk -v ssid="$ssid" '
        $1 == "SSID:" && $2 == ssid {
            f=1
        }
        f && /RSN/ {
            if ($2 ~ /PSK/) {
                print "psk2"
            } else if ($2 ~ /SAE/) {
                print "sae"
            } else {
                print "none"
            }
            exit
        }
    ')
    echo "${encryption:-none}"
}

# Get the encryption type
ENCRYPTION_TYPE=$(get_encryption_type "$NEW_SSID")

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

# Set encryption based on the detected type
case "$ENCRYPTION_TYPE" in
    sae)
        uci set wireless.wifinet1.encryption='sae'
        ;;
    psk2)
        uci set wireless.wifinet1.encryption='psk2'
        ;;
    none)
        uci set wireless.wifinet1.encryption='none'
        ;;
    *)
        echo "Unknown encryption type. Using 'psk-mixed' as fallback."
        uci set wireless.wifinet1.encryption='psk-mixed'
        ;;
esac

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
    echo "Detected Encryption: $ENCRYPTION_TYPE"
else
    echo "Error: Failed to update the wireless configuration."
    exit 1
fi
