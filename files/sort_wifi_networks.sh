#!/bin/sh

sort_networks_by_signal() {
    local json_input=$1

    echo "$json_input" | jq -r '
        sort_by(.signal) |
        .[] | .ssid
    '
}

sort_and_display_wifi_networks() {
    local scan_script_output

    # Run the scan script and capture its output
    scan_script_output=$(./scan_wifi_networks.sh)

    if [ $? -eq 0 ] && echo "$scan_script_output" | jq empty 2>/dev/null; then
        local sorted_ssids
        sorted_ssids=$(sort_networks_by_signal "$scan_script_output")
        echo "$sorted_ssids"
    else
        echo "Failed to obtain or parse Wi-Fi scan results" >&2
        return 1
    fi
}

sort_and_display_wifi_networks
