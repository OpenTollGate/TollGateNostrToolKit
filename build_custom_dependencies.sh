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
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file for ${ROUTER_TYPE} not found!"
    echo "Available options:"
    for file in "$ROUTERS_DIR"/*_config; do
        basename "${file}" | sed 's/_config$//'
    done
    exit 1
fi
cp $CONFIG_FILE $OPENWRT_DIR/.config


# Ensure toolchain directory exists
TOOLCHAIN_DIR="$OPENWRT_DIR/staging_dir/toolchain-mips_24kc_gcc-12.3.0_musl/host"
if [ ! -d "$TOOLCHAIN_DIR" ]; then
    echo "Creating missing toolchain directory: $TOOLCHAIN_DIR"
    mkdir -p "$TOOLCHAIN_DIR"
fi

make oldconfig

# Check for feed install errors
if [ $? -ne 0 ]; then
    echo "Feeds install failed"
    exit 1
fi

# Clean the build environment
echo "Cleaning the build environment..."
make clean

echo "Build with dependencies before using them..."
make -j$(nproc) V=sc > make_logs.md 2>&1
if [ $? -ne 0 ]; then
   echo "Firmware build failed."
   exit 1
fi

# Find and display the generated IPK file
echo "Finding the generated IPK files..."
TARGET_DIR="bin/packages/*/*"
find $TARGET_DIR -name "*secp256k1*.ipk"
find $TARGET_DIR -name "*libwebsockets*.ipk"
find $TARGET_DIR -name "*libwally*.ipk"
find $TARGET_DIR -name "*nodogsplash*.ipk"
find $TARGET_DIR -name "*gltollgate*.ipk"

BINARY_DIR="$HOME/TollGateNostrToolKit/binaries"
OUTPUT_BINARY="$BINARY_DIR/generate_npub_optimized_${ROUTER_TYPE}"

cp "$HOME/openwrt/build_dir/target-mips_24kc_musl/gltollgate-1.0/ipkg-mips_24kc/gltollgate/usr/bin/generate_npub" "$OUTPUT_BINARY" || {
   echo "Error: Failed to copy generate_npub to the TollGateNostrToolKit directory." >&2
   exit 1
}

tar -czvf "$BINARY_DIR/mips_24kc_packages_${ROUTER_TYPE}.tar.gz" -C "$HOME/openwrt/bin/packages" mips_24kc

echo "OpenWrt build completed successfully!"
