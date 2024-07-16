#!/bin/bash

# Define the function to check if websocat is set to true in .config
check_websocat_config() {
  if ! grep -q "^CONFIG_PACKAGE_websocat=y" .config; then
    echo "Error: websocat is not set to true in the .config file."
    exit 1
  fi
}

SCRIPT_DIR="$HOME/nostrSigner"
OPENWRT_DIR="$HOME/openwrt"
cd $OPENWRT_DIR

# Copy configuration files again
cp $SCRIPT_DIR/.config_websocat $OPENWRT_DIR/.config
cp $SCRIPT_DIR/feeds.conf $OPENWRT_DIR/feeds.conf
make oldconfig

check_websocat_config

# Update the websocat feed
echo "Updating websocat feed..."
./scripts/feeds update websocat

check_websocat_config

# Install the websocat package from the websocat feed
echo "Installing websocat package from websocat feed..."
PACKAGE_NAME="websocat"
./scripts/feeds install $PACKAGE_NAME

# Check for feed install errors
if [ $? -ne 0 ]; then
    echo "Feeds install failed"
    exit 1
fi

check_websocat_config

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

# Verify if websocat is set to true in .config
if ! grep -q "^CONFIG_PACKAGE_websocat=y" .config; then
  echo "After compile, Error: websocat is not set to true in the .config file."
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
