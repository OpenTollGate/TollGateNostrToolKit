#!/bin/bash

# Define the installation directories and compiler settings
SDK_URL="https://downloads.openwrt.org/releases/22.03.4/targets/ath79/generic/openwrt-sdk-22.03.4-ath79-generic_gcc-11.2.0_musl.Linux-x86_64.tar.xz"
SDK_ARCHIVE="${SDK_URL##*/}"
SDK_DIR="openwrt-sdk-22.03.4-ath79-generic_gcc-11.2.0_musl.Linux-x86_64"
CONFIG_FILE=".config"
EXPECTED_CHECKSUM="16b1ebf4d37eb7291235dcb8cfc973d70529164ef7531332255a2231cc1d5b79"
SOURCE_FILE="$PWD/sign_event.c"
MIPS_BINARY="$PWD/sign_event_mips"
LIB_DIR="$PWD/lib"
CUSTOM_FEED_DIR="$SDK_DIR/../custom"
CUSTOM_FEED_NAME="custom"
CUSTOM_FEED_URL="file://$PWD/$CUSTOM_FEED_DIR"

# Predefined configuration
CONFIG_CONTENT="CONFIG_TARGET_ath79=y
CONFIG_TARGET_ath79_generic=y
CONFIG_TARGET_ath79_generic_DEVICE_glinet_gl-ar300m=y
CONFIG_PACKAGE_busybox=y
CONFIG_PACKAGE_dnsmasq=y
CONFIG_PACKAGE_dropbear=y
CONFIG_PACKAGE_libc=y
CONFIG_PACKAGE_libgcc=y
CONFIG_PACKAGE_secp256k1=y
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

# Copy feeds.conf to SDK directory
echo "Copying feeds.conf to SDK directory..."
cp $SDK_DIR/../feeds.conf $SDK_DIR/

# Navigate to SDK directory
cd $SDK_DIR

# Add custom feed to feeds.conf if not already present
if ! grep -q "^src-link $CUSTOM_FEED_NAME" feeds.conf; then
    echo "Adding custom feed to feeds.conf..."
    echo "src-link $CUSTOM_FEED_NAME $CUSTOM_FEED_URL" >> feeds.conf
fi

# Update and install feeds
echo "Updating and installing feeds..."
./scripts/feeds update -a
./scripts/feeds install -a

# Set up the environment
echo "Setting up the environment..."
echo "$CONFIG_CONTENT" > $CONFIG_FILE
make defconfig

# Build the toolchain
echo "Installing toolchain..."
make -j$(nproc) V=s toolchain/install

# Build the secp256k1 package
echo "Building secp256k1 package..."
make -j$(nproc) V=s package/secp256k1/compile

if [ $? -ne 0 ]; then
    echo "Toolchain or secp256k1 package installation failed."
    exit 1
fi

# Compile the sign_event program for MIPS architecture
echo "Compiling sign_event.c for MIPS architecture..."
STAGING_DIR=$(pwd)/staging_dir
TOOLCHAIN_DIR=$STAGING_DIR/toolchain-mips_24kc_gcc-11.2.0_musl
export PATH=$TOOLCHAIN_DIR/bin:$PATH
export STAGING_DIR

# Make sure secp256k1 headers and libraries are available
SECP256K1_DIR="$LIB_DIR/secp256k1"
INCLUDE_DIR="$SECP256K1_DIR/include"
LIBS="-L$SECP256K1_DIR/.libs -lsecp256k1 -lgmp"

mips-openwrt-linux-gcc -I$INCLUDE_DIR -o $MIPS_BINARY $SOURCE_FILE $LIBS -static

if [ $? -eq 0 ]; then
    echo "Compilation successful: $MIPS_BINARY"
else
    echo "Failed to compile sign_event.c for MIPS architecture."
    exit 1
fi

# Transfer the binary to the router
ROUTER_IP="192.168.8.1"
REMOTE_PATH="/tmp"
REMOTE_USER="root"
REMOTE_PASS="1"
echo "Transferring $MIPS_BINARY to the router..."
scp $MIPS_BINARY $REMOTE_USER@$ROUTER_IP:$REMOTE_PATH/

# Run the binary on the router
echo "Running $MIPS_BINARY on the router..."
sshpass -p $REMOTE_PASS ssh $REMOTE_USER@$ROUTER_IP << EOF
chmod +x $REMOTE_PATH/$(basename $MIPS_BINARY)
$REMOTE_PATH/$(basename $MIPS_BINARY)
EOF

echo "Done!"

