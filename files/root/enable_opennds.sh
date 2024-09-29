#!/bin/sh

chmod 744 /usr/lib/opennds/theme_voucher.sh

touch /etc/config/opennds
uci add opennds opennds

uci set opennds.@opennds[0].login_option_enabled='3'
uci set opennds.@opennds[0].themespec_path='/usr/lib/opennds/theme_voucher.sh'
uci set opennds.@opennds[0].allow_preemptive_authentication=0
uci set opennds.@opennds[0].enabled=1

uci commit opennds

/etc/init.d/network restart
/etc/init.d/firewall restart
/etc/init.d/dnsmasq restart
/etc/init.d/opennds restart
service opennds enable

echo "Services restarted. Captive portal should now be functional."
