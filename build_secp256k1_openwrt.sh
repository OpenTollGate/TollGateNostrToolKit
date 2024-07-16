#!/bin/bash

# Define the function to check if secp256k1 is set to true in .config
check_secp256k1_config() {
  if ! grep -q "^CONFIG_PACKAGE_secp256k1=y" .config; then
    echo "Error: secp256k1 is not set to true in the .config file."
    exit 1
  fi
}

SCRIPT_DIR="$HOME/nostrSigner"
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

# Install the secp256k1 package from the custom feed
echo "Installing secp256k1 package from custom feed..."
PACKAGE_NAME="secp256k1"
./scripts/feeds install $PACKAGE_NAME

# Check for feed install errors
if [ $? -ne 0 ]; then
    echo "Feeds install failed"
    exit 1
fi

check_secp256k1_config

# Build the specific package
echo "Building the $PACKAGE_NAME package..."
make -j$(nproc) package/$PACKAGE_NAME/download V=s
if [ $? -ne 0 ]; then
    echo "$PACKAGE_NAME download failed."
    exit 1
fi

make -j$(nproc) package/$PACKAGE_NAME/check V=s
if [ $? -ne 0 ]; then
    echo "$PACKAGE_NAME check failed."
    exit 1
fi

make -j$(nproc) package/$PACKAGE_NAME/compile V=s
if [ $? -ne 0 ]; then
    echo "$PACKAGE_NAME compile failed."
    exit 1
fi

# Verify if secp256k1 is set to true in .config
if ! grep -q "^CONFIG_PACKAGE_secp256k1=y" .config; then
  echo "After compile, Error: secp256k1 is not set to true in the .config file."
  exit 1
fi

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
find $TARGET_DIR -name "*$PACKAGE_NAME*.ipk"

echo "OpenWrt build completed successfully!"
