#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 <target> <profile> <packages>"
    echo "Example: $0 ath79/nand glinet_gl-ar300m-nor 'luci luci-ssl openssh-sftp-server'"
    exit 1
}

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    usage
fi

# Configuration
OPENWRT_VERSION="23.05.4"
TARGET="$1"
PROFILE="$2"
PACKAGES="$3"

# Determine the Image Builder directory
BUILDER_DIR=$(find $HOME -maxdepth 1 -type d -name "openwrt-imagebuilder-*-${TARGET}-${SUBTARGET}-*" | head -n 1)

if [ -z "$BUILDER_DIR" ]; then
    echo "Error: Image Builder not found for ${TARGET}-${SUBTARGET}"
    echo "Searching for: openwrt-imagebuilder-*-${TARGET}*${SUBTARGET}*"
    echo "Available Image Builders:"
    find $HOME -maxdepth 1 -type d -name "openwrt-imagebuilder-*" -print
    echo "Debug: TARGET=$TARGET, SUBTARGET=$SUBTARGET"
    echo "Debug: BUILDER_DIR=$BUILDER_DIR"
    exit 1
fi


BINARIES_DIR="~/TollGateNostrToolKit/binaries"
OPENWRT_DIR="~/openwrt"

# Check if Image Builder directory exists
if [ ! -d "$BUILDER_DIR" ]; then
    echo "Error: OpenWrt Image Builder directory not found for target $TARGET."
    echo "Please run setup_dependencies.sh with the correct target first."
    exit 1
fi

# Create binaries directory if it doesn't exist
mkdir -p "$BINARIES_DIR"

# Change to the Image Builder directory
cd "$BUILDER_DIR" || exit 1

# Copy custom files from OpenWrt directory to Image Builder files directory
cp -R "$OPENWRT_DIR/files/" "$BUILDER_DIR/files/"

# Build the image
echo "Building OpenWrt image..."
echo "Target: $TARGET"
echo "Profile: $PROFILE"
echo "Packages: $PACKAGES"

make image PROFILE="$PROFILE" PACKAGES="$PACKAGES" FILES="files"

# Check if the build was successful
if [ $? -eq 0 ]; then
    echo "Build successful!"
    # Copy the generated sysupgrade.bin to the binaries directory
    find bin/targets -name "*-sysupgrade.bin" -exec cp {} "$BINARIES_DIR" \;
else
    echo "Build failed. Please check the output for errors."
fi

# Clean up
rm -rf "files"

# Return to the original directory
cd - > /dev/null
