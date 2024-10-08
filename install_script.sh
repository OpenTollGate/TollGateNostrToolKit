#!/bin/bash

set -e

# Check if the correct number of arguments are passed
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <SCRIPT_DIR> <OPENWRT_DIR>"
    exit 1
fi

# Get the arguments
SCRIPT_DIR="$1"
OPENWRT_DIR="$2"

# Debug: Print current paths and variables
echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "OPENWRT_DIR: $OPENWRT_DIR"

cd $OPENWRT_DIR

# Manually install custom files
echo "Manually installing custom files..."

if [ -d "$SCRIPT_DIR/files" ]; then
    # Create necessary directories
    mkdir -p "$OPENWRT_DIR/files/www/cgi-bin"
    mkdir -p "$OPENWRT_DIR/files/usr/local/bin"
    mkdir -p "$OPENWRT_DIR/files/usr/lib/opennds"
    mkdir -p "$OPENWRT_DIR/files/etc/uci-defaults"
    mkdir -p "$OPENWRT_DIR/files/etc/opennds/htdocs/images"
    mkdir -p "$OPENWRT_DIR/files/etc/config/"
    mkdir -p "$OPENWRT_DIR/files/etc/openvpn"
    mkdir -p "$OPENWRT_DIR/files/etc/init.d"
    mkdir -p "$OPENWRT_DIR/files/etc/rc.d"
     mkdir -p "$OPENWRT_DIR/files/etc"
    mkdir -p "$OPENWRT_DIR/files/root"

    cp "$SCRIPT_DIR/files/vpn/pia_latvia.ovpn" "$OPENWRT_DIR/files/etc/openvpn/"
    cp "$SCRIPT_DIR/files/vpn/firewall.user" "$OPENWRT_DIR/files/etc/"

    # Copy VPN setup and startup scripts
    cp "$SCRIPT_DIR/files/setup_vpn.sh" "$OPENWRT_DIR/files/etc/"
    cp "$SCRIPT_DIR/files/startup_vpn.sh" "$OPENWRT_DIR/files/etc/"
    chmod +x "$OPENWRT_DIR/files/etc/setup_vpn.sh"
    chmod +x "$OPENWRT_DIR/files/etc/startup_vpn.sh"

    # /uci-defaults and /root below broke the startup scripts and the
    # DHCP server on startup. Reintroduce with care!
    # cp "$SCRIPT_DIR/files/uci-defaults/"* "$OPENWRT_DIR/files/etc/uci-defaults/"
    # chmod +x "$OPENWRT_DIR/files/etc/uci-defaults/"*
    cp "$SCRIPT_DIR/files/root/"* "$OPENWRT_DIR/files/root/"
    chmod +x "$OPENWRT_DIR/files/root/"*
    
    cp "$SCRIPT_DIR/files/first-login-setup" "$OPENWRT_DIR/files/usr/local/bin/"
    chmod +x "$OPENWRT_DIR/files/usr/local/bin/first-login-setup"

    cp "$SCRIPT_DIR/files/etc/opennds/htdocs/images/splash.jpg" "$OPENWRT_DIR/files/etc/opennds/htdocs/images/splash.jpg"
    cp "$SCRIPT_DIR/files/etc/opennds/htdocs/splash.css" "$OPENWRT_DIR/files/etc/opennds/htdocs/splash.css"
    cp "$SCRIPT_DIR/files/usr/lib/opennds/"* "$OPENWRT_DIR/files/usr/lib/opennds/."
    chmod +x "$OPENWRT_DIR/files/usr/lib/opennds/"*
    
    cp "$SCRIPT_DIR/files/create_gateway.sh" "$OPENWRT_DIR/files/etc/"
    cp "$SCRIPT_DIR/files/activate_tollgate.sh" "$OPENWRT_DIR/files/etc/"
    cp "$SCRIPT_DIR/files/deactivate_tollgate.sh" "$OPENWRT_DIR/files/etc/"
    cp "$SCRIPT_DIR/files/cgi-bin/"*.sh "$OPENWRT_DIR/files/www/cgi-bin/"

    # Select DHCP server
    # cp "$SCRIPT_DIR/files/etc/init.d/"* "$OPENWRT_DIR/files/etc/init.d/"
    cp "$SCRIPT_DIR/files/etc/init.d/hotspot_manager" "$OPENWRT_DIR/files/etc/init.d/."
    cp "$SCRIPT_DIR/files/etc/rc.local" "$OPENWRT_DIR/files/etc/"


    # Set execute permissions
    chmod +x "$OPENWRT_DIR/files/etc/create_gateway.sh"

    # Copy uci_commands.sh and make it run on first boot
    mkdir -p "$OPENWRT_DIR/files/etc/opkg/"
    cp "$SCRIPT_DIR/files/distfeeds.conf" "$OPENWRT_DIR/files/etc/opkg/distfeeds.conf"

    # Append the profile addon to /etc/profile
    cp "$SCRIPT_DIR/files/etc/profile" "$OPENWRT_DIR/files/etc/profile"
    chmod +x "$OPENWRT_DIR/files/etc/profile"
    cat "$SCRIPT_DIR/files/profile.addon" >> "$OPENWRT_DIR/files/etc/profile"
    cp "$SCRIPT_DIR/files/etc/config/"* "$OPENWRT_DIR/files/etc/config/"

    echo "Custom files copied to OpenWrt files directory"
else
    echo "Custom files directory not found. Skipping manual installation."
fi
