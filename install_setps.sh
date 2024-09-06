#!/bin/bash

set -e


SCRIPT_DIR="$HOME/TollGateNostrToolKit"
ROUTERS_DIR="$SCRIPT_DIR/routers"
OPENWRT_DIR="$HOME/openwrt"
CUSTOM_FILES_DIR="$SCRIPT_DIR/files"
DESTINATION_DIR="$OPENWRT_DIR/package/base-files/files"

cd $OPENWRT_DIR


# Manually install custom files
echo "Manually installing custom files..."
CUSTOM_FILES_DIR="$SCRIPT_DIR/files"
DESTINATION_DIR="$OPENWRT_DIR/package/base-files/files"
if [ -d "$CUSTOM_FILES_DIR" ]; then
	# Create necessary directories
	mkdir -p "$DESTINATION_DIR/etc/uci-defaults"
	mkdir -p "$DESTINATION_DIR/usr/local/bin"
	mkdir -p "$DESTINATION_DIR/etc/init.d"
	mkdir -p "$DESTINATION_DIR/etc/rc.d"
	mkdir -p "$DESTINATION_DIR/www/cgi-bin"
	mkdir -p "$DESTINATION_DIR/etc/nodogsplash/htdocs"
	mkdir -p "$DESTINATION_DIR/etc/"
	mkdir -p "$DESTINATION_DIR/etc/config/"

	# Copy files from the custom directory to the OpenWrt files directory
	cp "$CUSTOM_FILES_DIR/80_mount_root" "$DESTINATION_DIR/etc/uci-defaults/"
	cp "$CUSTOM_FILES_DIR/first-login-setup" "$DESTINATION_DIR/usr/local/bin/"
	cp "$CUSTOM_FILES_DIR/create_gateway.sh" "$DESTINATION_DIR/etc/"
	cp "$CUSTOM_FILES_DIR/activate_tollgate.sh" "$DESTINATION_DIR/etc/"
	cp "$CUSTOM_FILES_DIR/deactivate_tollgate.sh" "$DESTINATION_DIR/etc/"
	cp "$CUSTOM_FILES_DIR/cgi-bin/"*.sh "$DESTINATION_DIR/www/cgi-bin/"
	cp -r "$CUSTOM_FILES_DIR/nodogsplash" "$DESTINATION_DIR/etc/config/"
	cp -r "$CUSTOM_FILES_DIR/etc/nodogsplash/htdocs/"* "$DESTINATION_DIR/etc/nodogsplash/htdocs/"
	cp -r "$CUSTOM_FILES_DIR/firewall.nodogsplash" "$DESTINATION_DIR/etc/"
	cp -r "$CUSTOM_FILES_DIR/etc/nodogsplash" "$DESTINATION_DIR/etc/"

	# Set execute permissions
	chmod +x "$DESTINATION_DIR/usr/local/bin/first-login-setup"
	chmod +x "$DESTINATION_DIR/etc/create_gateway.sh"

	# Copy uci_commands.sh and make it run on first boot
	mkdir -p "$DESTINATION_DIR/etc/opkg/"
	cp "$CUSTOM_FILES_DIR/distfeeds.conf" "$DESTINATION_DIR/etc/opkg/distfeeds.conf"
	cp "$CUSTOM_FILES_DIR/uci_commands.sh" "$DESTINATION_DIR/etc/uci-defaults/99-custom-settings"
	chmod +x "$DESTINATION_DIR/etc/uci-defaults/99-custom-settings"

	# Directly modify /etc/profile
	cat << 'EOF' >> "$DESTINATION_DIR/etc/profile"

# TollGateNostr first login setup
if [ ! -f /etc/first_login_done ] && [ "$SSH_TTY" != "" -o "$(tty)" = "/dev/tts/0" ]; then
    /usr/local/bin/first-login-setup
fi
EOF

    # Create a startup script
    cat << 'EOF' > "$DESTINATION_DIR/etc/init.d/99-run-first-login"
#!/bin/sh /etc/rc.common

START=99

start() {
    if [ ! -f /etc/first_login_done ]; then
        /usr/local/bin/first-login-setup
    fi
}
EOF

    chmod +x "$DESTINATION_DIR/etc/init.d/99-run-first-login"
    ln -sf ../init.d/99-run-first-login "$DESTINATION_DIR/etc/rc.d/S99run-first-login"

    # Create UCI defaults script
    cat << 'EOF' > "$DESTINATION_DIR/etc/uci-defaults/99-first-login-setup"
#!/bin/sh

[ -f /etc/first_login_done ] || {
    /usr/local/bin/first-login-setup
}

exit 0
EOF

	chmod +x "$DESTINATION_DIR/etc/uci-defaults/99-first-login-setup"
    
	echo "Custom files copied to OpenWrt files directory"
else
	echo "Custom files directory not found. Skipping manual installation."
fi
