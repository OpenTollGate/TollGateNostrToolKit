#!/bin/sh

# Sort the networks by signal in descending order
sort_networks_by_signal_desc() {
    local json_input="$1"
    echo "$json_input" | jq -r '
        map(.signal |= tonumber) |
        sort_by(-.signal)
    '
}

# Remove JSON tuples with empty SSIDs
remove_empty_ssids() {
    local json_input="$1"
    echo "$json_input" | jq -r '
        map(select(.ssid != ""))
    '
}

# Remove duplicate SSIDs, keeping the first instance (strongest signal already first after sort)
remove_duplicate_ssids() {
    local json_input="$1"
    echo "$json_input" | jq -r '
        reduce .[] as $item ({}; 
            if .[$item.ssid] == null then . + { ($item.ssid): $item } else . end
        ) | [.[]]
    '
}

# Capture, sort, and display the full JSON data
sort_and_display_full_json() {
    local scan_script_output
    scan_script_output=$(./scan_wifi_networks.sh)

    if [ $? -eq 0 ] && echo "$scan_script_output" | jq empty 2>/dev/null; then
        local filtered_json
        filtered_json=$(remove_empty_ssids "$scan_script_output")
        
        local sorted_json
        sorted_json=$(sort_networks_by_signal_desc "$filtered_json")
        local removed_duplicates
        removed_duplicates=$(remove_duplicate_ssids "$sorted_json")
        
        echo "$removed_duplicates"
    else
        echo "Failed to obtain or parse Wi-Fi scan results" >&2
        return 1
    fi
}

# Function to select an SSID from the list
select_ssid() {
    local sorted_json
    sorted_json=$(sort_and_display_full_json)

    if [ $? -ne 0 ]; then
        return 1
    fi

    # Capture SSID List
    local ssid_list
    ssid_list=$(echo "$sorted_json" | jq -r '.[] | .ssid')

    if [ -z "$ssid_list" ]; then
        echo "No SSIDs available to select."
        return 1
    fi

    echo "Available SSIDs:"
    i=1
    while IFS= read -r ssid; do
        echo "$i) $ssid"
        eval "ssid_$i='$ssid'"
        i=$((i+1))
    done <<EOF
$ssid_list
EOF

    while true; do
        read -p "Enter the number of the SSID you want to connect to: " selection
        if [ "$selection" -ge 1 ] 2>/dev/null && [ "$selection" -lt "$i" ]; then
            eval "selected_ssid=\$ssid_$selection"
            echo "You selected SSID: $selected_ssid"
            echo "$selected_ssid"
            return 0
        else
            echo "Invalid selection. Please enter a valid number."
        fi
    done
}

main() {
    case $1 in
        --full-json)
            sort_and_display_full_json
            ;;
        --ssid-list)
            local sorted_json
            sorted_json=$(sort_and_display_full_json)
            echo "$sorted_json" | jq -r '.[] | .ssid'
            ;;
        --select-ssid)
            select_ssid
            ;;
        *)
            echo "Usage: $0 [--full-json | --ssid-list | --select-ssid]"
            return 1
            ;;
    esac
}

main "$@"
