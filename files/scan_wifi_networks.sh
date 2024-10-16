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

    ip link set "$interface" up

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
                encryption = "Open"
            }
            mac = $2
            sub(/\(.*/, "", mac)
            ssid = ""
            signal = ""
        }
        $1 == "SSID:" { ssid = substr($0, index($0, $2)) }
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

scan_until_success() {
    local output
    local retries=10
    local delay=2

    for i in $(seq 1 $retries); do
        output=$(scan_wifi_networks_to_json)
        ret_code=$?

        if [ $ret_code -eq 0 ]; then
            # Check if JSON output is valid
            if echo "$output" | jq empty 2>/dev/null; then
                echo "$output" | jq '.'
                return 0
            fi
        elif [ $ret_code -eq 2 ]; then
            echo "Resource busy, retrying in $delay second(s)... ($i/$retries)" >&2
        else
            echo "Scan failed, retrying in $delay second(s)... ($i/$retries)" >&2
        fi

        sleep $delay
    done

    echo "Failed to scan Wi-Fi networks after $retries attempts" >&2
    return 1
}

scan_until_success
