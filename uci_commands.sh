
uci set network.lan.ipaddr='192.168.8.1'
uci commit network 

uci set wireless.default_radio0.ssid='TollGate'      # Set the SSID
uci set wireless.default_radio0.encryption='none'    # Set encryption to WPA2-PSK
#uci set wireless.default_radio0.key='password'  # Set the Wi-Fi password
uci set wireless.default_radio0.network='lan'        # Bind the Wi-Fi to the LAN network
uci set wireless.default_radio0.disable='0'        # Bind the Wi-Fi to the LAN network
uci commit wireless

echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf
/etc/init.d/dnsmasq restart

/etc/init.d/network restart

rootpassword="tollgate"
/bin/passwd root << EOF
$rootpassword
$root password
EOF
