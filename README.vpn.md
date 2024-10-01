## security

todo: check that a random password is set, or else anyone can log in to luci if you allow wan access

## allow 443 and 80

lets encrypt needs 80 and 443

## lets encrypt

opkg update
opkg install acme-acmesh

domain=mydomain.com
email=mail@mydomain.com

acme.sh --issue --webroot /www -d ${domain} --cert-home /etc/acme --accountemail ${email} --reloadcmd "/etc/init.d/uhttpd reload"

rm -f /etc/uhttpd.crt
rm -f /etc/uhttpd.key

ln -s /etc/acme/${domain}_ecc/fullchain.cer /etc/uhttpd.crt
ln -s /etc/acme/${domain}_ecc/${domain}.key /etc/uhttpd.key

/etc/init.d/uhttpd restart

## install the client config file

#todo: generate a new certifiate instead of using this one

ssh myvpn mkdir -p /www/rest
scp files/www/rest/GetUserlogin  myvpn:/www/rest/

test that this works `curl https://vpn.dns4sats.xyz/rest/GetUserlogin`


## install openvpn

opkg install openvpn-openssl
opkg install luci-app-openvpn


todo: test openvpn-mbedtls on router

## openvpn certs

using hardcoded certs for now. Not secure. Need to generate new ones with openvpn-easy-rsa



## forwarding and firewall

allow all or set a custom exit policy

## openvpn server config files

scp -r files/etc/openvpn myvpn:/etc/

## running openvpn

todo: find out if it runs on boot or needs to be started manually
