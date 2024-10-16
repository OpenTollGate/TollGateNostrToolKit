#!/bin/sh

# Function to get the first managed mode Wi-Fi interface
get_wifi_interface() {
    iw dev | awk '$1 == "Interface" { iface=$2 } $1 == "type" && $2 == "managed" { print iface; exit }'
}

# Function to scan available Wi-Fi networks
scan_wifi_networks() {
    local interface=$(get_wifi_interface)

    # Ensure the interface is up
    ip link set $interface up

    # Scan for networks and parse the output
    iw dev $interface scan | awk '
        $1 == "BSS" {
            mac = $2
        }
        $1 == "signal:" {
            signal = $2
        }
        $1 == "SSID:" {
            ssid = $0
            sub(/^SSID: /, "", ssid)  # Remove the "SSID: " prefix
            # Print the result as SSID, MAC, and Signal Strength
            print "SSID: " ssid ", MAC: " mac ", Signal: " signal " dBm"
        }'
}

# Execute the function and display the available networks
echo "Available Wi-Fi Networks:"
echo "-------------------------"
scan_wifi_networks
