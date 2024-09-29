#!/bin/sh

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

# Restart services with delays
/etc/init.d/network restart
sleep 2
/etc/init.d/firewall restart
sleep 2
/etc/init.d/dnsmasq restart
sleep 2

# Restart uhttpd if you're using it
if [ -f /etc/init.d/uhttpd ]; then
    /etc/init.d/uhttpd restart
    sleep 2
fi

# Restart OpenNDS last
/etc/init.d/opennds restart

echo "Services restarted. Captive portal should now be functional."
