#!/bin/bash

set -e

SCRIPT_DIR="$HOME/TollGateNostrToolKit"
ROUTERS_DIR="$SCRIPT_DIR/routers"

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <router_type>"
    echo "Available options:"
    for file in "$ROUTERS_DIR"/*_config; do
        basename "${file}" | sed 's/_config$//'
    done
    exit 1
fi

ROUTER_TYPE=$1

OPENWRT_DIR="$HOME/openwrt"
cd $OPENWRT_DIR

cp $SCRIPT_DIR/feeds.conf $OPENWRT_DIR/feeds.conf

# Update the custom feed
echo "Updating custom feed..."
./scripts/feeds update -a

# Install the dependencies from the custom feed
echo "Installing dependencies from custom feed..."
./scripts/feeds install -a

# Copy configuration files
CONFIG_FILE="$ROUTERS_DIR/${ROUTER_TYPE}_config"
if [! -f "$CONFIG_FILE" ]; then
    echo "Configuration file for ${ROUTER_TYPE} not found!"
    echo "Available options:"
    for file in "$ROUTERS_DIR"/*_config; do
        basename "${file}" | sed 's/_config$//'
    done
    exit 1
fi
cp $CONFIG_FILE $OPENWRT_DIR/.config

make oldconfig

# Check for feed install errors
if [ $? -ne 0 ]; then
    echo "Feeds install failed"
    exit 1
fi

# Clean the build environment
echo "Cleaning the build environment..."
make clean

# Install the toolchain
echo "Installing toolchain..."
make -j$(nproc) toolchain/install
if [ $? -ne 0 ]; then
    echo "Toolchain install failed"
    exit 1
fi

echo "Building firmware..."
make -j$(nproc) V=sc > make_logs.md 2>&1
if [ $? -ne 0 ]; then
   echo "Firmware build failed."
   exit 1
fi

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
	mkdir -p "$DESTINATION_DIR/etc/firewall.nodogsplash"

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
	chmod +x "$DESTINATION_DIR/etc/connect_to_gateway.sh"

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

# Rebuild firmware to include manual changes
echo "Rebuilding firmware..."
make -j$(nproc) V=sc >> make_logs.md 2>&1
if [ $? -ne 0 ]; then
   echo "Firmware rebuild failed."
   exit 1
fi

# Find and display the generated IPK files
echo "Finding the generated IPK files..."
TARGET_DIR="$OPENWRT_DIR/bin/packages"

# Array of file patterns to search for
file_patterns=(
    "libwebsockets*.ipk"
    "libwally*.ipk"
    "nodogsplash*.ipk"
    "gltollgate*.ipk"
    "relaylink*.ipk"
    "signevent*.ipk"
)

# Flag to track if all files are found
all_files_found=true

# Loop through each file pattern
for pattern in "${file_patterns[@]}"; do
    # Find the file
    found_file=$(find "$TARGET_DIR" -type f -name "$pattern")
    
    # Check if the file was found
    if [ -z "$found_file" ]; then
        echo "Error: $pattern not found"
        all_files_found=false
    else
        echo "Found: $found_file"
    fi
done

# Exit with status 1 if any file wasn't found
if [ "$all_files_found" = false ]; then
    echo "One or more required IPK files were not found."
    exit 1
fi

echo "All required IPK files were found successfully."

# Find the sysupgrade.bin file
SYSUPGRADE_FILE=$(find "$OPENWRT_DIR/bin" -type f -name "*sysupgrade.bin")

# Check if file was found
if [ -z "$SYSUPGRADE_FILE" ]; then
    echo "No sysupgrade.bin file found."
    exit 1
fi

# Copy the file to the destination directory
cp "$SYSUPGRADE_FILE" ~/TollGateNostrToolKit/binaries/.

# Check if copy was successful
if [ $? -eq 0 ]; then
    echo "Successfully copied $(basename "$SYSUPGRADE_FILE") to ~/TollGateNostrToolKit/binaries/."
else
    echo "Failed to copy file."
    exit 1
fi

echo "OpenWrt build completed successfully!"
