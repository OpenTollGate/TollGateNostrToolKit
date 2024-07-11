#!/bin/bash

# Variables
HELLO_C="hello.c"
HELLO_MIPS="hello_mips"
ROUTER_IP="192.168.8.1"
REMOTE_PATH="/tmp"
REMOTE_USER="root"
REMOTE_PASS="1"
SDK_URL="https://downloads.openwrt.org/releases/22.03.4/targets/ath79/generic/openwrt-sdk-22.03.4-ath79-generic_gcc-11.2.0_musl.Linux-x86_64.tar.xz"
SDK_ARCHIVE="${SDK_URL##*/}"
SDK_DIR="openwrt-sdk-22.03.4-ath79-generic_gcc-11.2.0_musl.Linux-x86_64"
CONFIG_FILE=".config"
EXPECTED_CHECKSUM="16b1ebf4d37eb7291235dcb8cfc973d70529164ef7531332255a2231cc1d5b79"

# Predefined configuration
CONFIG_CONTENT="CONFIG_TARGET_ath79=y
CONFIG_TARGET_ath79_generic=y
CONFIG_TARGET_ath79_generic_DEVICE_glinet_gl-ar300m=y
CONFIG_PACKAGE_busybox=y
CONFIG_PACKAGE_dnsmasq=y
CONFIG_PACKAGE_dropbear=y
CONFIG_PACKAGE_libc=y
CONFIG_PACKAGE_libgcc=y"

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

# Navigate to SDK directory
cd $SDK_DIR

# Set up the environment and compile the toolchain
echo "Setting up the environment..."
echo "$CONFIG_CONTENT" > $CONFIG_FILE
make defconfig
make toolchain/install

# Create the Hello World Program
echo "Creating hello.c..."
echo '#include <stdio.h>

int main() {
    printf("Hello, World!\\n");
    return 0;
}' > $HELLO_C

# Compile the Hello World Program
echo "Compiling hello.c..."
STAGING_DIR=$(pwd)/staging_dir
PATH=$STAGING_DIR/toolchain-mips_24kc_gcc-11.2.0_musl/bin:$PATH
mips-openwrt-linux-gcc -o $HELLO_MIPS $HELLO_C

# Transfer the binary to the router
echo "Transferring $HELLO_MIPS to the router..."
scp $HELLO_MIPS $REMOTE_USER@$ROUTER_IP:$REMOTE_PATH/

# Run the binary on the router
echo "Running $HELLO_MIPS on the router..."
sshpass -p $REMOTE_PASS ssh $REMOTE_USER@$ROUTER_IP << EOF
chmod +x $REMOTE_PATH/$HELLO_MIPS
$REMOTE_PATH/$HELLO_MIPS
EOF

# Cleanup
echo "Cleaning up..."
cd ..
rm -f $HELLO_C $HELLO_MIPS

echo "Done!"

