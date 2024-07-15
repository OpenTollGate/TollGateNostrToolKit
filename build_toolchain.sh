#!/bin/bash

# Get the directory of the script
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
OPENWRT_DIR="$HOME/openwrt"

cd $OPENWRT_DIR

# Copy configuration files
cp $SCRIPT_DIR/.config $OPENWRT_DIR/.config
cp $SCRIPT_DIR/feeds.conf $OPENWRT_DIR/feeds.conf

# Update and install all feeds
./scripts/feeds update -a
./scripts/feeds install -a

make -j$(nproc) toolchain/install
if [ $? -ne 0 ]; then
    echo "Toolchain install failed"
    exit 1
fi
