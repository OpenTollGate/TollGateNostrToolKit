#!/bin/bash

# Configuration
OPENWRT_VERSION="23.05.4"
TARGET="ath79/nand"
BUILDER_DIR="openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET/\//-}.Linux-x86_64"
PROFILE="glinet_gl-ar300m-nor"
PACKAGES="luci luci-ssl openssh-sftp-server"

# Check if Image Builder directory exists
if [ ! -d "$BUILDER_DIR" ]; then
  echo "Error: OpenWrt Image Builder directory not found. Please run setup_dependencies.sh first."
  exit 1
fi

# Change to the Image Builder directory
cd "$BUILDER_DIR" || exit 1

# Build the image
echo "Building OpenWrt image..."
make image PROFILE="$PROFILE" PACKAGES="$PACKAGES"

# Check if the build was successful
if [ $? -eq 0 ]; then
  echo "Build successful!"
  echo "The image can be found in the bin/targets/${TARGET}/ directory."
else
  echo "Build failed. Please check the output for errors."
fi
