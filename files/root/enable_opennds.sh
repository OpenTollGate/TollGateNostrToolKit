#!/bin/sh

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

touch /etc/config/opennds
uci add opennds opennds

uci set opennds.@opennds[0].login_option_enabled='3'
uci set opennds.@opennds[0].themespec_path='/usr/lib/opennds/theme_voucher.sh'
uci set opennds.@opennds[0].allow_preemptive_authentication=0
uci set opennds.@opennds[0].enabled=1

uci commit opennds

# Enable OpenNDS before restarting
service opennds enable

# Restart services using &&
/etc/init.d/network restart && \
/etc/init.d/odhcpd restart && \
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

echo "Services restarted. Captive portal should now be functional."
