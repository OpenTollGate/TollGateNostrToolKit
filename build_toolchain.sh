#!/bin/bash

# Get the directory of the script
SCRIPT_DIR="$HOME/nostrSigner"
OPENWRT_DIR="$HOME/openwrt"

cd $OPENWRT_DIR || { echo "Failed to cd to $OPENWRT_DIR"; exit 1; }

# WARNING: your configuration is out of sync. Please run make menuconfig, oldconfig or defconfig!
cp $SCRIPT_DIR/.config $OPENWRT_DIR/.config
cp $SCRIPT_DIR/feeds.conf $OPENWRT_DIR/feeds.conf

# Ensure toolchain directory exists
TOOLCHAIN_DIR="$OPENWRT_DIR/staging_dir/toolchain-mips_24kc_gcc-12.3.0_musl/host"
if [ ! -d "$TOOLCHAIN_DIR" ]; then
    echo "Creating missing toolchain directory: $TOOLCHAIN_DIR"
    mkdir -p "$TOOLCHAIN_DIR"
fi

make oldconfig

# Update and install all feeds
echo "Updating feeds..."
./scripts/feeds update -a
if [ $? -ne 0 ]; then
    echo "Feeds update failed"
    exit 1
fi

echo "Installing feeds..."
./scripts/feeds install -a
if [ $? -ne 0 ]; then
    echo "Feeds install failed"
    exit 1
fi

cp $SCRIPT_DIR/.config_after_update $OPENWRT_DIR/.config
make oldconfig

# Install the toolchain
echo "Installing toolchain..."
make -j$(nproc) toolchain/install
if [ $? -ne 0 ]; then
    echo "Toolchain install failed"
    exit 1
fi

