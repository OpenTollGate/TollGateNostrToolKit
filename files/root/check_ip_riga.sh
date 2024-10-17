#!/bin/sh

# Function to get current public IP and its location
get_ip_location() {
    local ip=$(curl -s ifconfig.me)
    local location=$(curl -s "http://ip-api.com/csv/${ip}?fields=country,city" | tr ',' ' ')
    echo "$location"
}

# Check if the IP location is in Riga
ip_location=$(get_ip_location)
if (echo "$ip_location" | grep -q "Latvia Riga"); then
    echo "IP location is in Riga: $ip_location"
else
    echo "IP location is not in Riga: $ip_location. Restarting VPN..."
    service openvpn restart
fi
