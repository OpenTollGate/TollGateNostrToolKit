#!/bin/sh

# Function to get current public IP
get_public_ip() {
    curl -s ifconfig.me
}

# Function to get IP location
get_ip_location() {
    local ip=$1
    local location=$(curl -s "http://ip-api.com/csv/${ip}?fields=country,regionName,city" | tr ',' ' ')
    echo "$ip ($location)"
}

# Function to get first hop IP from traceroute
get_first_hop() {
    traceroute -m 2 -n 8.8.8.8 | awk 'NR==2 {print $2; exit}'
}

# Function to validate IP address format
is_valid_ip() {
    case "$1" in
        ""|*[!0-9.]*) return 1 ;;
        *) return 0 ;;
    esac
}

# Get the current public IP (which should be your VPN IP)
vpn_ip=$(get_public_ip)
echo "Your current public IP (VPN IP): $(get_ip_location $vpn_ip)"

# Get the first hop IP
first_hop=$(get_first_hop)
echo "First hop IP: $(get_ip_location $first_hop)"

# Check if first hop matches VPN subnet
if echo "$first_hop" | grep -q "^${vpn_ip%.*}"; then
    echo "PASS: First hop matches VPN subnet"
else
    echo "WARN: First hop doesn't match VPN subnet"
fi

# DNS servers to test
dns_servers="208.67.222.222 208.67.220.220 1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4"

# Function to perform DNS lookup
dns_lookup() {
    nslookup myip.opendns.com "$1" | awk '/^Address: / { print $2 }' | tail -n1
}

# Perform DNS leak test
echo "Performing DNS leak test..."
for server in $dns_servers; do
    echo "Testing DNS server $(get_ip_location $server): "
    result=$(dns_lookup "$server")
    if [ "$result" = "$vpn_ip" ]; then
        echo "PASS (IP: $(get_ip_location $result))"
    else
        echo "INFO (Expected: $(get_ip_location $vpn_ip), Got: $(get_ip_location $result))"
    fi
done

# Additional checks
echo "Performing additional checks..."
ipify_result=$(curl -s https://api.ipify.org)
echo "ipify.org IP check: $(get_ip_location $ipify_result)"

# Additional check using dig and Akamai service
echo "Performing Akamai check..."
dig_result=$(dig +short @8.8.8.8 whoami.akamai.net)
if ! is_valid_ip "$dig_result"; then
    echo "ERROR: Akamai check failed. Connection to DNS server (8.8.8.8) was refused, timed out, or returned an invalid response."
    akamai_status="FAIL"
else
    echo "Akamai IP check: $(get_ip_location $dig_result)"
    if [ "$dig_result" != "$vpn_ip" ]; then
        echo "WARN (Akamai check doesn't match VPN-IP: Akamai $(get_ip_location $dig_result), VPN-IP $(get_ip_location $vpn_ip))"
        akamai_status="WARN"
    else
        echo "PASS (Akamai check matches VPN-IP: Akamai $(get_ip_location $dig_result), VPN-IP $(get_ip_location $vpn_ip))"
        akamai_status="PASS"
    fi
fi

# Perform traceroute if Akamai check failed or doesn't match VPN-IP
if [ "$akamai_status" != "PASS" ]; then
    echo "Performing traceroute to 8.8.8.8:"
    traceroute -n 8.8.8.8
fi

# Final assessment
if echo "$first_hop" | grep -q "^${vpn_ip%.*}" && \
   [ "$ipify_result" = "$vpn_ip" ] && \
   [ "$akamai_status" = "PASS" ]; then
    echo "All tests passed. No DNS leaks detected."
else
    echo "WARNING: Potential issues detected. Please review the results carefully."
    exit 1
fi

exit 0
