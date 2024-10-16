#!/bin/sh

# Sort the networks by signal in descending order
sort_networks_by_signal_desc() {
    local json_input=$1

    echo "$json_input" | jq -r '
        map(.signal |= tonumber) |
        sort_by(-.signal)
    '
}

# Remove JSON tuples with empty SSIDs
remove_empty_ssids() {
    local json_input=$1

    echo "$json_input" | jq -r '
        map(select(.ssid != ""))
    '
}

# Remove duplicate SSIDs, keeping the first instance (strongest signal already first after sort)
remove_duplicate_ssids() {
    local json_input=$1

    echo "$json_input" | jq -r '
        reduce .[] as $item ({}; 
            if .[$item.ssid] == null then . + { ($item.ssid): $item } else . end
        ) | [.[]]
    '
}

# Capture, sort, and display Wi-Fi networks as SSIDs
sort_and_display_ssid_list() {
    local sorted_json=$1

    echo "$sorted_json" | jq -r '
        .[] | .ssid
    '
}

# Capture, sort, and display the full JSON data
sort_and_display_full_json() {
    local scan_script_output

    # Run the scan script and capture its output
    scan_script_output=$(./scan_wifi_networks.sh)

    if [ $? -eq 0 ] && echo "$scan_script_output" | jq empty 2>/dev/null; then
        local filtered_json
        filtered_json=$(remove_empty_ssids "$scan_script_output")
        
        # Sort networks by signal first, then remove duplicates
        local sorted_json
        sorted_json=$(sort_networks_by_signal_desc "$filtered_json")
        removed_duplicates=$(remove_duplicate_ssids "$sorted_json")
        
        echo "$removed_duplicates"
    else
        echo "Failed to obtain or parse Wi-Fi scan results" >&2
        return 1
    fi
}

main() {
    if [ "$1" = "--full-json" ]; then
        sort_and_display_full_json
    elif [ "$1" = "--ssid-list" ]; then
        local sorted_json
        sorted_json=$(sort_and_display_full_json)
        sort_and_display_ssid_list "$sorted_json"
    else
        echo "Usage: $0 [--full-json | --ssid-list]"
        return 1
    fi
}

main "$@"
