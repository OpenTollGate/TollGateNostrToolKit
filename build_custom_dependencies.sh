#!/bin/bash

set -e

# Define the function to check if secp256k1 is set to true in .config
check_secp256k1_config() {
  if ! grep -q "^CONFIG_PACKAGE_secp256k1=y" .config; then
    echo "Error: secp256k1 is not set to true in the .config file."
    exit 1
  fi
}

SCRIPT_DIR="$HOME/TollGateNostrToolKit"
OPENWRT_DIR="$HOME/openwrt"
cd $OPENWRT_DIR

# Copy configuration files again
cp $SCRIPT_DIR/.config_secp256k1 $OPENWRT_DIR/.config
cp $SCRIPT_DIR/feeds.conf $OPENWRT_DIR/feeds.conf
make oldconfig

check_secp256k1_config

# Update the custom feed
echo "Updating custom feed..."
./scripts/feeds update custom

check_secp256k1_config

# Install the dependencies from the custom feed
echo "Installing dependencies from custom feed..."
./scripts/feeds install libwebsockets libopenssl secp256k1

# Check for feed install errors
if [ $? -ne 0 ]; then
    echo "Feeds install failed"
    exit 1
fi

check_secp256k1_config

# Build the specific packages
echo "Building the dependencies..."
make -j$(nproc) package/libwebsockets/download V=s
make -j$(nproc) package/secp256k1/download V=s

make -j$(nproc) package/libwebsockets/check V=s
make -j$(nproc) package/secp256k1/check V=s

make -j$(nproc) package/libwebsockets/compile V=s
make -j$(nproc) package/secp256k1/compile V=s


check_secp256k1_config


# Build the firmware
echo "Building the firmware..."
make -j$(nproc) V=s
if [ $? -ne 0 ]; then
    echo "Firmware build failed."
    exit 1
fi

# Find and display the generated IPK file
echo "Finding the generated IPK file..."
TARGET_DIR="bin/packages/*/*"
find $TARGET_DIR -name "*secp256k1*.ipk"
find $TARGET_DIR -name "*libwebsockets*.ipk"

echo "OpenWrt build completed successfully!"

