#!/bin/sh

# Restart network service
/etc/init.d/network restart

# Restart firewall (you've already included this, but it's good to run it again after network restart)
/etc/init.d/firewall restart

# Restart OpenVPN service (also included in your original commands)
/etc/init.d/openvpn restart

# Restart DNS forwarder (usually dnsmasq on OpenWrt)
/etc/init.d/dnsmasq restart

# Restart DHCP server (if separate from dnsmasq)
/etc/init.d/odhcpd restart

# Reload UCI configuration
uci commit

# Optionally, flush the routing cache
ip route flush cache

/etc/init.d/firewall restart
/etc/init.d/openvpn start
/etc/init.d/openvpn enable
