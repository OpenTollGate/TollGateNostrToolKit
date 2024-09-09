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
    mkdir -p "$OPENWRT_DIR/files/etc/nodogsplash/htdocs"
    mkdir -p "$OPENWRT_DIR/files/etc/uci-defaults"
    mkdir -p "$OPENWRT_DIR/files/etc/config/"
    mkdir -p "$OPENWRT_DIR/files/etc/init.d"
    mkdir -p "$OPENWRT_DIR/files/etc/rc.d"
    mkdir -p "$OPENWRT_DIR/files/etc"

    # Copy files from the custom directory to the OpenWrt files directory

    cp "$SCRIPT_DIR/files/80_mount_root" "$OPENWRT_DIR/files/etc/uci-defaults/"

    cp "$SCRIPT_DIR/files/first-login-setup" "$OPENWRT_DIR/files/usr/local/bin/"
    cp "$SCRIPT_DIR/files/create_gateway.sh" "$OPENWRT_DIR/files/etc/"
    cp "$SCRIPT_DIR/files/activate_tollgate.sh" "$OPENWRT_DIR/files/etc/"
    cp "$SCRIPT_DIR/files/deactivate_tollgate.sh" "$OPENWRT_DIR/files/etc/"
    cp "$SCRIPT_DIR/files/cgi-bin/"*.sh "$OPENWRT_DIR/files/www/cgi-bin/"
    cp -r "$SCRIPT_DIR/files/nodogsplash" "$OPENWRT_DIR/files/etc/config/"
    cp -r "$SCRIPT_DIR/files/etc/nodogsplash/htdocs/"* "$OPENWRT_DIR/files/etc/nodogsplash/htdocs/"
    cp -r "$SCRIPT_DIR/files/firewall.nodogsplash" "$OPENWRT_DIR/files/etc/"
    cp -r "$SCRIPT_DIR/files/etc/nodogsplash" "$OPENWRT_DIR/files/etc/"

    # Set execute permissions
    chmod +x "$OPENWRT_DIR/files/usr/local/bin/first-login-setup"
    chmod +x "$OPENWRT_DIR/files/etc/create_gateway.sh"

    # Copy uci_commands.sh and make it run on first boot
    mkdir -p "$OPENWRT_DIR/files/etc/opkg/"
    cp "$SCRIPT_DIR/files/distfeeds.conf" "$OPENWRT_DIR/files/etc/opkg/distfeeds.conf"
    cp "$SCRIPT_DIR/files/uci_commands.sh" "$OPENWRT_DIR/files/etc/uci-defaults/99-custom-settings"
    chmod +x "$OPENWRT_DIR/files/etc/uci-defaults/99-custom-settings"

    # Directly modify /etc/profile
    cat << 'EOF' >> "$OPENWRT_DIR/files/etc/profile"

# TollGateNostr first login setup
if [ ! -f /etc/first_login_done ] && [ -t 0 ] && [ -t 1 ]; then
    /usr/local/bin/first-login-setup
fi
EOF

    chmod +x "$OPENWRT_DIR/files/etc/uci-defaults/80_mount_root"
    echo "Custom files copied to OpenWrt files directory"
else
    echo "Custom files directory not found. Skipping manual installation."
fi
