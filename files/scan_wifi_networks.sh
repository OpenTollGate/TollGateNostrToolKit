#!/bin/sh

get_wifi_interface() {
    iw dev | awk '$1 == "Interface" { iface=$2 } $1 == "type" && $2 == "managed" { print iface; exit }'
}

scan_wifi_networks_to_json() {
    local interface=$(get_wifi_interface)
    echo "Detected Wi-Fi interface: $interface"

    if [ -z "$interface" ]; then
        echo "No managed Wi-Fi interface found"
        return 1
    fi

    ip link set $interface up
    ip link show $interface

    networks="[]"

    echo "Running iw scan..."
    if ! iw dev "$interface" scan; then
        echo "Scan failed. Error: $?"
        return 1
    fi

    echo "Processing scan results..."
    iw dev "$interface" scan | awk '
        BEGIN { OFS = ""; print "Debug: Starting awk script" > "/dev/stderr"; }
        {print "Debug: Processing line: " $0 > "/dev/stderr"}
        $1 == "BSS" {
            mac = $2
            sub(/\(.*/, "", mac)
            print "Debug: Found BSS, MAC: " mac > "/dev/stderr"
            print "{ \"mac\": \"" mac "\" }"
        }
        END { print "Debug: Finished awk script" > "/dev/stderr"; }
    ' | while IFS= read -r line; do
        networks=$(echo "$networks" | jq --argjson new_ap "$line" '. += [$new_ap]')
        if [ $? -ne 0 ]; then
            echo "jq error occurred"
            return 1
        fi
    done
    
    echo "$networks" | jq
}

echo "Scanning Wi-Fi Networks..."
scan_wifi_networks_to_json
