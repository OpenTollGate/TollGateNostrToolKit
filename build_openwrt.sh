#!/bin/bash

# Define the installation directories and compiler settings
SDK_URL="https://downloads.openwrt.org/releases/22.03.4/targets/ath79/generic/openwrt-sdk-22.03.4-ath79-generic_gcc-11.2.0_musl.Linux-x86_64.tar.xz"
SDK_ARCHIVE="${SDK_URL##*/}"
SDK_DIR="openwrt-sdk-22.03.4-ath79-generic_gcc-11.2.0_musl.Linux-x86_64"
CONFIG_FILE=".config"
FEEDS_FILE="feeds_no_custom.conf"
EXPECTED_CHECKSUM="16b1ebf4d37eb7291235dcb8cfc973d70529164ef7531332255a2231cc1d5b79"

# Predefined configuration
CONFIG_CONTENT="CONFIG_TARGET_ath79=y
CONFIG_TARGET_ath79_generic=y
CONFIG_TARGET_ath79_generic_DEVICE_glinet_gl-ar300m=y
CONFIG_PACKAGE_busybox=y
CONFIG_PACKAGE_dnsmasq=y
CONFIG_PACKAGE_dropbear=y
CONFIG_PACKAGE_libc=y
CONFIG_PACKAGE_libgcc=y
CONFIG_PACKAGE_libopenssl=y"

# Function to check checksum
check_checksum() {
    echo "Checking checksum..."
    local checksum=$(sha256sum $SDK_ARCHIVE | awk '{ print $1 }')
    if [ "$checksum" == "$EXPECTED_CHECKSUM" ]; then
        echo "Checksum matches."
        return 0
    else
        echo "Checksum does not match."
        return 1
    fi
}

# Install required packages
echo "Installing required packages..."
sudo apt-get update
sudo apt-get install -y build-essential libncurses5-dev libncursesw5-dev git python3 rsync file wget

# Download and extract the OpenWrt SDK if not already downloaded
if [ ! -d "$SDK_DIR" ]; then
    if [ ! -f "$SDK_ARCHIVE" ] || ! check_checksum; then
        echo "Downloading OpenWrt SDK..."
        wget $SDK_URL
    fi
    echo "Extracting OpenWrt SDK..."
    tar -xvf $SDK_ARCHIVE
else
    echo "OpenWrt SDK already downloaded and extracted."
fi

# Copy feeds_no_custom.conf to SDK directory as feeds.conf
echo "Copying feeds_no_custom.conf to SDK directory as feeds.conf..."
cp $SDK_DIR/../$FEEDS_FILE $SDK_DIR/feeds.conf

# Navigate to SDK directory
cd $SDK_DIR

# Update and install feeds
echo "Updating and installing feeds..."
./scripts/feeds update -a

if [ $? -ne 0 ]; then
    echo "Feeds update failed"
    exit 1
fi

./scripts/feeds install -a

if [ $? -ne 0 ]; then
    echo "Feeds install failed"
    exit 1
fi

# Set up the environment
echo "Setting up the environment..."
echo "$CONFIG_CONTENT" | tee $CONFIG_FILE > /dev/null
make defconfig

if [ $? -ne 0 ]; then
    echo "Failed to make defconfig."
    exit 1
fi

# Build the toolchain
echo "Installing toolchain..."
make clean
make -j$(nproc) V=s toolchain/install

if [ $? -ne 0 ]; then
    echo "Toolchain install failed."
    exit 1
fi

echo "OpenWrt build completed successfully!"

