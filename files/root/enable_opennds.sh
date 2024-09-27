  #!/bin/sh
  #opkg update
  #opkg install opennds



  cd /usr/lib/opennds
  #wget https://raw.githubusercontent.com/openNDS/openNDS/master/community/themespec/theme_voucher/theme_voucher.sh
  #wget https://raw.githubusercontent.com/Amperstrand/openNDS/claim-lnurlw-or-cashu-payments/community/themespec/theme_voucher/theme_voucher.sh
  wget https://raw.githubusercontent.com/Amperstrand/openNDS/POC-test/community/themespec/theme_voucher/theme_voucher.sh
  mkdir -p /tmp/ndslog
  cd /tmp/ndslog
  wget https://raw.githubusercontent.com/openNDS/openNDS/master/community/themespec/theme_voucher/vouchers.txt && 
  chmod 744 /usr/lib/opennds/theme_voucher.sh &&


  mv /etc/config/opennds /root/etc_config_opennds
  mv  /etc/opennds/config.uci /root/etc_opennds_config.uci
  
  rm /etc/config/opennds /root/etc_config_opennds
  rm  /etc/opennds/config.uci /root/etc_opennds_config.uci

  touch /etc/config/opennds
  uci add opennds opennds

  uci set opennds.@opennds[0].login_option_enabled='3' &&
  uci set opennds.@opennds[0].themespec_path='/usr/lib/opennds/theme_voucher.sh' &&
  uci set opennds.@opennds[0].allow_preemptive_authentication=0 &&
  uci set opennds.@opennds[0].enabled=1 &&


  uci commit opennds &&
  service opennds restart &&
  service opennds enable &&
  reboot
  #sleep 10
  #service network restart

