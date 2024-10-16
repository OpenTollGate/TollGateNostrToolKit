#!/bin/sh

# Function to get the first managed mode Wi-Fi interface
get_wifi_interface() {
    iw dev | awk '$1 == "Interface" { iface=$2 } $1 == "type" && $2 == "managed" { print iface; exit }'
}

# Function to scan available Wi-Fi networks and construct JSON
scan_wifi_networks_to_json() {
    local interface=$(get_wifi_interface)

    if [ -z "$interface" ]; then
        echo "No managed Wi-Fi interface found"
        return 1
    fi

    # Ensure the interface is up
    ip link set $interface up

    # Store JSON results
    networks="[]"

    iw dev $interface scan

    # Scan for networks and populate JSON
    iw dev $interface scan | awk '
        BEGIN { OFS = ""; capture = 0 }
        $1 == "BSS" { 
            mac = substr($2, 1, length($2)-1) # Remove trailing parenthesis
        }
        $1 == "signal:" { 
            signal = $2 
        }
        $1 == "SSID:" { 
            ssid = $2
        }
        $1 == "RSN:" { 
            capture = 1 
            encryption = "psk" # assume RSN indicates WPA2 with PSK as default
        }
        $1 == "*" && capture == 1 { 
            if ($2 ~ /SAE/) {
                encryption = "sae"
            } else if ($2 ~ /PSK/) {
                encryption = "psk"
            } else {
                encryption = "unknown"
            }
        }
        $1 == "" { 
            if (ssid != "") {
                print "{ \"ssid\": \"" ssid "\", \"mac\": \"" mac "\", \"signal\": " signal ", \"encryption\": \"" encryption "\" }"
            }
            ssid = ""; mac = ""; signal = ""; encryption = "none"; capture = 0
        }
    ' | while IFS= read -r line; do
        networks=$(echo "$networks" | jq --argjson new_ap "$line" '. += [$new_ap]')
    done

    # Print the full JSON object
    echo "$networks" | jq
}

# Execute the function and display the available networks in JSON
echo "Scanning Wi-Fi Networks..."
scan_wifi_networks_to_json
