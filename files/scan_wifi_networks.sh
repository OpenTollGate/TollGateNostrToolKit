#!/bin/sh

get_wifi_interface() {
    iw dev | awk '$1 == "Interface" { iface=$2 } $1 == "type" && $2 == "managed" { print iface; exit }'
}

scan_wifi_networks_to_json() {
    local interface=$(get_wifi_interface)
    echo "Detected Wi-Fi interface: $interface" >&2

    if [ -z "$interface" ]; then
        echo "No managed Wi-Fi interface found" >&2
        return 1
    fi

    ip link set $interface up
    ip link show $interface >&2

    echo "Running iw scan..." >&2
    if ! iw dev "$interface" scan; then
        echo "Scan failed. Error: $?" >&2
        return 1
    fi

    echo "Processing scan results..." >&2
    iw dev "$interface" scan | awk '
        BEGIN { 
            print "[" 
            first = 1
        }
        $1 == "BSS" {
            mac = $2
            sub(/\(.*/, "", mac)
            if (!first) print ","
            printf "  {\"mac\": \"%s\"}", mac
            first = 0
        }
        END { print "\n]" }
    ' | jq '.'
}

echo "Scanning Wi-Fi Networks..."
scan_wifi_networks_to_json
