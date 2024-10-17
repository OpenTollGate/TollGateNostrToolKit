#!/bin/sh

get_hotspot_ssid() {
    if [ -f "/nostr/shell/nostr_keys.json" ]; then
        npub=$(jq -r ".npub_hex" /nostr/shell/nostr_keys.json 2>/dev/null)
        if [ -n "$npub" ] && [ "$npub" != "null" ]; then
            echo "TollGate_${npub:0:8}"
            return
        fi
    fi
    
    mac_address=$(cat /sys/class/ieee80211/phy0/macaddress | sed "s/://g")
    echo "TollGate_${mac_address}"
}

hotspot_ssid=$(get_hotspot_ssid)
echo "$hotspot_ssid"
