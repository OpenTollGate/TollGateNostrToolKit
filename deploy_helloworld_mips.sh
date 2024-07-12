#!/bin/bash

# Function to check if the script is run as root
if [ "$EUID" -eq 0 ]; then
  echo "Please do not run this script as root"
  exit 1
fi

# Variables
HELLO_C="hello.c"
HELLO_MIPS="hello_mips"
ROUTER_IP="192.168.8.1"
REMOTE_PATH="/tmp"
REMOTE_USER="root"
REMOTE_PASS="1"
OPENWRT_DIR=~/Documents/openwrt
CONFIG_FILE=".config"

# Predefined configuration
CONFIG_CONTENT="CONFIG_TARGET_ath79=y
CONFIG_TARGET_ath79_generic=y
CONFIG_TARGET_ath79_generic_DEVICE_glinet_gl-ar300m=y
CONFIG_PACKAGE_busybox=y
CONFIG_PACKAGE_dnsmasq=y
CONFIG_PACKAGE_dropbear=y
CONFIG_PACKAGE_libc=y
CONFIG_PACKAGE_libgcc=y"

# Navigate to the existing OpenWrt build directory
cd $OPENWRT_DIR

# Clean existing .config and set up the environment
if [ -f "$CONFIG_FILE" ]; then
    echo "Cleaning existing .config file..."
    rm $CONFIG_FILE
fi

echo "Setting up the environment..."
echo "$CONFIG_CONTENT" > $CONFIG_FILE
make defconfig

# Compile the toolchain if not already done
if [ ! -d "$OPENWRT_DIR/staging_dir" ]; then
    make toolchain/install
else
    echo "Toolchain already set up."
fi

# Create the Hello World Program
echo "Creating hello.c..."
echo '#include <stdio.h>

int main() {
    printf("Hello, World!\\n");
    return 0;
}' > $HELLO_C

# Compile the Hello World Program
echo "Compiling hello.c..."
STAGING_DIR=$OPENWRT_DIR/staging_dir
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
rm -f $HELLO_C $HELLO_MIPS

echo "Done!"

