#!/bin/sh

# This script is basically a combination of disable_ipv6.sh and
# enable_opennds.sh. I tried to remove things that might not be
# necessary for getting a DHCP lease, but whenever I made changes I
# didn't get a DHCP lease anymore... Feel free to remove things if you
# think they are not contributing towards getting a DHCP lease, but
# please test those changes before merging to main.

uci set 'network.lan.ipv6=0'
uci set 'network.wan.ipv6=0'
uci set 'dhcp.lan.dhcpv6=disabled'
/etc/init.d/odhcpd disable
uci commit
uci -q delete dhcp.lan.dhcpv6
uci -q delete dhcp.lan.ra
uci commit dhcp
/etc/init.d/odhcpd restart

# Function to check if OpenNDS is running and responsive
check_opennds() {
    ndsctl json >/dev/null 2>&1
    return $?
}

# Wait for OpenNDS to start, with a timeout
wait_for_opennds() {
    echo "Waiting for OpenNDS to start..."
    
    local timeout=60  # Timeout in seconds
    local start_time=$(date +%s)
    
    while ! check_opennds; do
        sleep 1
        local current_time=$(date +%s)
        local elapsed_time=$((current_time - start_time))
        
        if [ $elapsed_time -ge $timeout ]; then
            echo "Timeout waiting for OpenNDS to start"
            return 1
        fi
    done
    
    echo "OpenNDS has started successfully"
    return 0
}

chmod 744 /usr/lib/opennds/theme_voucher.sh

# Enable OpenNDS before restarting
service opennds enable

# Restart services using &&
/etc/init.d/network restart && \
fw3 flush && \
/etc/init.d/firewall restart && \
/etc/init.d/dnsmasq restart && \
# Restart uhttpd if it exists
([ -f /etc/init.d/uhttpd ] && /etc/init.d/uhttpd restart || true) && \

# Restart OpenNDS
/etc/init.d/opennds restart

# Wait for OpenNDS to start
if wait_for_opennds; then
    echo "OpenNDS is now running and responsive"
    # You can add additional commands here that depend on OpenNDS being fully started
else
    echo "Failed to start OpenNDS within the timeout period"
    exit 1
fi

echo "Services restarted. DHCP lease should now be assigned."

