#!/bin/bash

set -e

SCRIPT_DIR="$HOME/TollGateNostrToolKit"
ROUTERS_DIR="$SCRIPT_DIR/routers"
OPENWRT_DIR="$HOME/openwrt"
cd $OPENWRT_DIR

# Manually install custom files
echo "Manually installing custom files..."
CUSTOM_FILES_DIR="$SCRIPT_DIR/files"
if [ -d "$CUSTOM_FILES_DIR" ]; then
    # Create necessary directories
    mkdir -p "$OPENWRT_DIR/files/etc/uci-defaults"
    mkdir -p "$OPENWRT_DIR/files/usr/local/bin"
    mkdir -p "$OPENWRT_DIR/files/etc/init.d"
    mkdir -p "$OPENWRT_DIR/files/etc/rc.d"
    
    # Copy files from the custom directory to the OpenWrt files directory
    cp "$CUSTOM_FILES_DIR/80_mount_root" "$OPENWRT_DIR/files/etc/uci-defaults/"
    cp "$CUSTOM_FILES_DIR/first-login-setup" "$OPENWRT_DIR/files/usr/local/bin/"
    cp "$CUSTOM_FILES_DIR/create_gateway.sh" "$OPENWRT_DIR/files/etc/"
    cp "$CUSTOM_FILES_DIR/activate_tollgate.sh" "$OPENWRT_DIR/files/etc/"
    cp "$CUSTOM_FILES_DIR/deactivate_tollgate.sh" "$OPENWRT_DIR/files/etc/"

    # Set execute permissions
    chmod +x "$OPENWRT_DIR/files/usr/local/bin/first-login-setup"
    chmod +x "$OPENWRT_DIR/files/etc/connect_to_gateway.sh"

    # Copy uci_commands.sh and make it run on first boot
    mkdir -p "$OPENWRT_DIR/files/etc/opkg/"
    cp "$CUSTOM_FILES_DIR/distfeeds.conf" "$OPENWRT_DIR/files/etc/opkg/distfeeds.conf"
    cp "$CUSTOM_FILES_DIR/uci_commands.sh" "$OPENWRT_DIR/files/etc/uci-defaults/99-custom-settings"
    chmod +x "$OPENWRT_DIR/files/etc/uci-defaults/99-custom-settings"

    # Directly modify /etc/profile
    cat << 'EOF' >> "$OPENWRT_DIR/files/etc/profile"

# TollGateNostr first login setup
if [ ! -f /etc/first_login_done ] && [ "$SSH_TTY" != "" -o "$(tty)" = "/dev/tts/0" ]; then
    /usr/local/bin/first-login-setup
fi
EOF

    # Create a startup script
    cat << 'EOF' > "$OPENWRT_DIR/files/etc/init.d/99-run-first-login"
#!/bin/sh /etc/rc.common

START=99

start() {
    if [ ! -f /etc/first_login_done ]; then
        /usr/local/bin/first-login-setup
    fi
}
EOF

    chmod +x "$OPENWRT_DIR/files/etc/init.d/99-run-first-login"
    ln -sf ../init.d/99-run-first-login "$OPENWRT_DIR/files/etc/rc.d/S99run-first-login"

    # Create UCI defaults script
    cat << 'EOF' > "$OPENWRT_DIR/files/etc/uci-defaults/99-first-login-setup"
#!/bin/sh

[ -f /etc/first_login_done ] || {
    /usr/local/bin/first-login-setup
}

exit 0
EOF

    chmod +x "$OPENWRT_DIR/files/etc/uci-defaults/99-first-login-setup"
    
    echo "Custom files copied to OpenWrt files directory"
else
    echo "Custom files directory not found. Skipping manual installation."
fi
