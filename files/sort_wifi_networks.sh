#!/bin/sh

# Sort the networks by signal
sort_networks_by_signal() {
    local json_input=$1

    echo "$json_input" | jq -r '
        sort_by(.signal)
    '
}

# Remove JSON tuples with empty SSIDs
remove_empty_ssids() {
    local json_input=$1

    echo "$json_input" | jq -r '
        map(select(.ssid != ""))
    '
}

# Remove duplicate SSIDs, keeping the first instance
remove_duplicate_ssids() {
    local json_input=$1

    echo "$json_input" | jq -r '
        reduce .[] as $item ({}; . + { ($item.ssid): $item }) | 
        [.[]]
    '
}

# Capture, sort, and display the full JSON data
sort_and_display_full_json() {
    local scan_script_output

    # Run the scan script and capture its output
    scan_script_output=$(./scan_wifi_networks.sh)

    if [ $? -eq 0 ] && echo "$scan_script_output" | jq empty 2>/dev/null; then
        local filtered_json
        filtered_json=$(remove_empty_ssids "$scan_script_output") # | remove_duplicate_ssids)
        
        local sorted_json
	# TODO: sort first, then filter - we want to remove duplicates that have a less powerful signal. 
        sorted_json=$(sort_networks_by_signal "$filtered_json")
        echo "$sorted_json"
    else
        echo "Failed to obtain or parse Wi-Fi scan results" >&2
        return 1
    fi
}


sort_and_display_full_json
