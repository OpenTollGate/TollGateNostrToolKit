#!/bin/sh

get_wifi_interface() {
    iw dev | awk '$1 == "Interface" { iface=$2 } $1 == "type" && $2 == "managed" { print iface; exit }'
}

scan_wifi_networks_to_json() {
    local interface=$(get_wifi_interface)
    # echo "Detected Wi-Fi interface: $interface" >&2

    if [ -z "$interface" ]; then
        echo "No managed Wi-Fi interface found" >&2
        return 1
    fi

    ip link set $interface up
    # ip link show $interface >&2

    # echo "Processing scan results..." >&2
    iw dev "$interface" scan | awk '
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
                printf "  {\"mac\": \"%s\", \"ssid\": \"%s\", \"encryption\": \"%s\", \"signal\": \"%s dBm\"}", mac, ssid, encryption, signal
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
        $1 == "signal:" { signal = $2 }
        END {
            if (mac != "") {
                if (!first) print ","
                printf "  {\"mac\": \"%s\", \"ssid\": \"%s\", \"encryption\": \"%s\", \"signal\": \"%s dBm\"}", mac, ssid, encryption, signal
            }
            print "\n]"
        }
    ' | jq '.'
}

scan_wifi_networks_to_json
