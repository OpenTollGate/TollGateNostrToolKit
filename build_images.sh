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

# Split TARGET into TARGET and SUBTARGET
TARGET_MAIN=$(echo $TARGET | cut -d'/' -f1)
SUBTARGET=$(echo $TARGET | cut -d'/' -f2)

echo "Debug: Current working directory: $(pwd)"
echo "Debug: Script location: $0"
echo "Debug: HOME directory: $HOME"

echo "Running setup_dependencies_for_image_builder.sh..."
$HOME/TollGateNostrToolKit/setup_dependencies_for_image_builder.sh "$TARGET"
echo "Setup dependencies script completed."

echo "Debug: Image Builder directory after setup:"
ls -l "$HOME/openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET_MAIN}-${SUBTARGET}.Linux-x86_64"

# Determine the Image Builder directory
BUILDER_DIR="$HOME/openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET_MAIN}-${SUBTARGET}.Linux-x86_64"

if [ ! -d "$BUILDER_DIR" ]; then
    echo "Error: Image Builder not found at $BUILDER_DIR"
    echo "Available Image Builders:"
    find $HOME -maxdepth 1 -type d -name "openwrt-imagebuilder-*" -print
    echo "Debug: TARGET=$TARGET"
    echo "Debug: TARGET_MAIN=$TARGET_MAIN"
    echo "Debug: SUBTARGET=$SUBTARGET"
    echo "Debug: BUILDER_DIR=$BUILDER_DIR"
    exit 1
fi

echo "Using Image Builder at: $BUILDER_DIR"

BINARIES_DIR="$HOME/TollGateNostrToolKit/binaries"
OPENWRT_DIR="$HOME/openwrt"

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
