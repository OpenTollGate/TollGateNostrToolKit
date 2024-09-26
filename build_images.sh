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
TARGET="$1"
PROFILE="$2"
PACKAGES="$3"

# Split TARGET into TARGET and SUBTARGET
TARGET_MAIN=$(echo $TARGET | cut -d'/' -f1)
SUBTARGET=$(echo $TARGET | cut -d'/' -f2)

echo "Debug: Current working directory: $(pwd)"
echo "Debug: Script location: $0"
echo "Debug: HOME directory: $HOME"


# Add this function near the top of the script
download_image_builder() {
    local builder_dir="openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET_MAIN}-${SUBTARGET}.Linux-x86_64"
    local builder_archive="${builder_dir}.tar.xz"
    local download_url="https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/${TARGET_MAIN}/${SUBTARGET}/${builder_archive}"

    echo "Downloading OpenWrt Image Builder for ${TARGET_MAIN}/${SUBTARGET}..."
    wget "$download_url"

    if [ $? -ne 0 ]; then
        echo "Failed to download Image Builder. Please check if the target is correct."
        exit 1
    fi

    echo "Extracting OpenWrt Image Builder..."
    tar xJf "$builder_archive"

    if [ $? -ne 0 ]; then
        echo "Failed to extract Image Builder archive."
        exit 1
    fi

    echo "Cleaning up..."
    rm "$builder_archive"

    mv "$builder_dir" "$HOME/openwrt/"
}

# Determine the Image Builder directory
OPENWRT_VERSION="23.05.4"
BUILDER_DIR="$HOME/openwrt/openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET_MAIN}-${SUBTARGET}.Linux-x86_64"

echo "Using Image Builder at: $BUILDER_DIR"

# Check if Image Builder directory exists
if [ ! -d "$BUILDER_DIR" ]; then
    echo "Image Builder not found. Attempting to download..."
    download_image_builder
else
    echo "Image Builder found at: $BUILDER_DIR"
fi

# Check if Image Builder directory exists now
if [ ! -d "$BUILDER_DIR" ]; then
    echo "Error: Image Builder still not found after download attempt."
    echo "Available Image Builders:"
    find $HOME/openwrt -maxdepth 1 -type d -name "openwrt-imagebuilder-*" -print
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
echo "Copying custom files..."
mkdir -p "$BUILDER_DIR/files"
cp -R "$OPENWRT_DIR/files/"* "$BUILDER_DIR/files/"

echo "Custom files in Image Builder:"
ls -R "$BUILDER_DIR/files"

# Build the image
echo "Building OpenWrt image..."
echo "Target: $TARGET"
echo "Profile: $PROFILE"
echo "Packages: $PACKAGES"

make image PROFILE="$PROFILE" PACKAGES="$PACKAGES" FILES="files" V=sc

# Check if the build was successful
if [ $? -eq 0 ]; then
    echo "Build successful!"
    # Copy the generated sysupgrade.bin to the binaries directory
    find bin/targets -name "*-sysupgrade.bin" -exec cp {} "$BINARIES_DIR" \;
else
    echo "Build failed. Please check the output for errors."
fi

# Do not clean up the files directory
# rm -rf "files"

# Return to the original directory
cd - > /dev/null
