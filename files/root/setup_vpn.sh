#!/bin/sh

# Function to check if a package is installed
is_package_installed() {
    opkg list-installed | grep -q "^$1 "
}

# Function to install a package if it's not already installed
install_package_if_needed() {
    if ! is_package_installed "$1"; then
        if [ "$update_run" != "true" ]; then
            opkg update
            update_run=true
        fi
        opkg install "$1"
    fi
}

# Install necessary packages if they're not already installed
update_run=false
install_package_if_needed "luci-app-openvpn"
install_package_if_needed "openvpn-openssl"
install_package_if_needed "bind-tools"

# Prompt user for username and password
# echo "Please enter your VPN username:"
# read username
# echo "Please enter your VPN password:"
# read -s password

username="p4523384"
password="Nostrhackday1"

# Save username and password to auth.txt
echo -e "$username\n$password" > /etc/openvpn/auth.txt

echo "VPN credentials saved to /etc/openvpn/auth.txt"
echo "VPN setup complete."
