#!/bin/bash

set -e

SCRIPT_DIR="$HOME/TollGateNostrToolKit"
OPENWRT_DIR="$HOME/openwrt"
cd $OPENWRT_DIR

# Clean the build environment
# echo "Cleaning the build environment..."
# make clean

# Copy configuration files again
cp $SCRIPT_DIR/.config_secp256k1 $OPENWRT_DIR/.config
cp $SCRIPT_DIR/feeds.conf $OPENWRT_DIR/feeds.conf
make oldconfig

# Update the custom feed
echo "Updating custom feed..."
./scripts/feeds update custom

# Install the dependencies from the custom feed
echo "Installing dependencies from custom feed..."
./scripts/feeds install libwebsockets libopenssl secp256k1 libwally nostr_client_relay gltollgate

# Check for feed install errors
if [ $? -ne 0 ]; then
    echo "Feeds install failed"
    exit 1
fi


# Build the specific packages
echo "Building libwebsockets..."
make -j$(nproc) package/libwebsockets/download V=s
make -j$(nproc) package/libwebsockets/check V=s
make -j$(nproc) package/libwebsockets/compile V=s

echo "Building secp256k1..."
make -j$(nproc) package/secp256k1/download V=s
make -j$(nproc) package/secp256k1/check V=s
make -j$(nproc) package/secp256k1/compile V=s

echo "Building libwally..."
make -j$(nproc) package/libwally/download V=s
make -j$(nproc) package/libwally/check V=s
make -j$(nproc) package/libwally/compile V=s

echo "Build with dependencies before using them..."
make -j$(nproc) V=s
if [ $? -ne 0 ]; then
    echo "Firmware build failed."
    exit 1
fi

# echo "Building nostr_client_relay..."
# make -j$(nproc) package/nostr_client_relay/download V=s
# make -j$(nproc) package/nostr_client_relay/check V=s
# make -j$(nproc) package/nostr_client_relay/compile V=s

echo "Building gltollgate..."
# make -j$(nproc) package/gltollgate/download V=s
# make -j$(nproc) package/gltollgate/check V=s
# make -j$(nproc) package/gltollgate/compile V=s

# Build the firmware
# echo "Building the firmware..."
# make -j$(nproc) V=s
# if [ $? -ne 0 ]; then
#    echo "Firmware build failed."
#     exit 1
# fi

# Find and display the generated IPK file
echo "Finding the generated IPK file..."
TARGET_DIR="bin/packages/*/*"
find $TARGET_DIR -name "*secp256k1*.ipk"
find $TARGET_DIR -name "*libwebsockets*.ipk"
find $TARGET_DIR -name "*libwally*.ipk"
# find $TARGET_DIR -name "*nostr_client_relay*.ipk"
# find $TARGET_DIR -name "*gltollgate*.ipk"

echo "OpenWrt build completed successfully!"

