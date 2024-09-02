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
BUILDER_DIR="openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET/\//-}.Linux-x86_64"

# Check if Image Builder directory exists
if [ ! -d "$BUILDER_DIR" ]; then
    echo "Error: OpenWrt Image Builder directory not found for target $TARGET."
    echo "Please run setup_dependencies.sh with the correct target first."
    exit 1
fi

# Change to the Image Builder directory
cd "$BUILDER_DIR" || exit 1

# Create a temporary file for UCI defaults
UCI_DEFAULTS_FILE="files/etc/uci-defaults/99-custom-settings"
mkdir -p "files/etc/uci-defaults"
cat > "$UCI_DEFAULTS_FILE" << EOF
#!/bin/sh

$(cat ../uci_commands.sh)

exit 0
EOF

chmod +x "$UCI_DEFAULTS_FILE"

# Build the image
echo "Building OpenWrt image..."
echo "Target: $TARGET"
echo "Profile: $PROFILE"
echo "Packages: $PACKAGES"

make image PROFILE="$PROFILE" PACKAGES="$PACKAGES" FILES="files"

# Check if the build was successful
if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "The image can be found in the bin/targets/${TARGET}/ directory."
else
    echo "Build failed. Please check the output for errors."
fi

# Clean up
rm -rf "files"
