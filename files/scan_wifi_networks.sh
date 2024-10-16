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
        function escape_json_string(str, result, i, char) {
            result = ""
            for (i = 1; i <= length(str); i++) {
                char = substr(str, i, 1)
                if (char ~ /[\x00-\x1F\x22\x5C]/) {
                    # Escape special json characters and control characters
                    if (char == "\"") {
                        result = result "\\\""
                    } else if (char == "\\") {
                        result = result "\\\\"
                    } else if (char == "\b") {
                        result = result "\\b"
                    } else if (char == "\f") {
                        result = result "\\f"
                    } else if (char == "\n") {
                        result = result "\\n"
                    } else if (char == "\r") {
                        result = result "\\r"
                    } else if (char == "\t") {
                        result = result "\\t"
                    } else {
                        printf result "\\u00%02x", ord(char)
                    }
                } else {
                    result = result char
                }
            }
            return result
        }

        BEGIN {
            print "["
            first = 1
        }
        $1 == "BSS" {
            valid = (mac != "" && ssid != "" && signal != "")
            if (valid) {
                if (!first) print ","
                printf "  {\"mac\": \"%s\", \"ssid\": \"%s\", \"encryption\": \"%s\", \"signal\": %s}", mac, escape_json_string(ssid), encryption, signal
                first = 0
            }
            mac = $2
            sub(/\(.*/, "", mac)
            ssid = ""
            encryption = "Open"
            signal = ""
        }
        $1 == "SSID:" { ssid = substr($0, index($0, $2)); gsub(/^[[:space:]]+|[[:space:]]+$/, "", ssid) }
        $1 == "RSN:" { encryption = "WPA2" }
        $1 == "signal:" { sub(" dBm", "", $2); signal = $2 }
        END {
            valid = (mac != "" && ssid != "" && signal != "")
            if (valid) {
                if (!first) print ","
                printf "  {\"mac\": \"%s\", \"ssid\": \"%s\", \"encryption\": \"%s\", \"signal\": %s}", mac, escape_json_string(ssid), encryption, signal
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
