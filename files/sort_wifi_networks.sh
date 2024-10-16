#!/bin/sh

get_wifi_interface() {
    iw dev | awk '$1 == "Interface" { iface=$2 } $1 == "type" && $2 == "managed" { print iface; exit }'
}

scan_wifi_networks_to_json() {
    local interface=$(get_wifi_interface)

    if [ -z "$interface" ]; then
        echo "No managed Wi-Fi interface found" >&2
        return 1
    fi

    # Bring down the interface, then bring it back up
    ip link set $interface down
    sleep 1
    ip link set $interface up
    sleep 1

    # Perform the scan
    scan_result=$(iw dev "$interface" scan 2>&1)
    
    if echo "$scan_result" | grep -q "Resource busy"; then
        echo "Resource busy" >&2
        return 1
    fi

    echo "$scan_result" | awk '
        BEGIN { 
            print "[" 
            first = 1
            mac = ""
            ssid = ""
            encryption = "Open"
            signal = ""
        }
        $1 == "BSS" {
            if (mac != "") {
                if (!first) print ","
                printf "  {\"mac\": \"%s\", \"ssid\": \"%s\", \"encryption\": \"%s\", \"signal\": %s}", mac, ssid, encryption, signal
                first = 0
                encryption = "Open"  # Reset encryption to default for the next BSS block
            }
            mac = $2
            sub(/\(.*/, "", mac)
            ssid = ""
            signal = ""
        }
        $1 == "SSID:" { ssid = $2 }
        $1 == "RSN:" { encryption = "WPA2" }
        $1 == "signal:" { sub(" dBm", "", $2); signal = $2 }
        END {
            if (mac != "") {
                if (!first) print ","
                printf "  {\"mac\": \"%s\", \"ssid\": \"%s\", \"encryption\": \"%s\", \"signal\": %s}", mac, ssid, encryption, signal
            }
            print "\n]"
        }
    '
}

sort_networks_by_signal() {
    local json_input=$1

    echo "$json_input" | jq -r '
        sort_by(.signal) |
        .[] | .ssid
    '
}

scan_and_sort() {
    local output

    output=$(scan_wifi_networks_to_json)
    if [ $? -eq 0 ] && echo "$output" | jq empty 2>/dev/null; then
        local sorted_ssids
        sorted_ssids=$(sort_networks_by_signal "$output")
        echo "$sorted_ssids"
    else
        echo "Failed to obtain or parse Wi-Fi scan results" >&2
        return 1
    fi
}

scan_and_sort
