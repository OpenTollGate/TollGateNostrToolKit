#!/bin/bash

set -e

# Define necessary variables
SCRIPT_DIR="$HOME/TollGateNostrToolKit"
OPENWRT_DIR="$HOME/openwrt"
ROUTERS_DIR="$SCRIPT_DIR/routers"

# Define a function to map router types to target and subtarget
get_target_subtarget() {
    local router_type=$1
    case $router_type in
        "ath79_gl-ar300m-nor")
            echo "ath79 nand"
            ;;
        "ramips_mt7621")
            echo "ramips mt7621"
            ;;
        # Add more mappings here as needed
        *)
            echo "unknown unknown"
            ;;
    esac
}

# Debug: Print current paths and variables
echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "OPENWRT_DIR: $OPENWRT_DIR"

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <router_type>"
    echo "Available options:"
    for file in "$ROUTERS_DIR"/*_config; do
        basename "${file}" | sed 's/_config$//'
    done
    exit 1
fi

ROUTER_TYPE=$1

# Function to get the latest commit hash
get_latest_commit() {
    git -C "$1" rev-parse HEAD
}

# Function to extract custom feed URL and branch from feeds.conf
get_custom_feed_info() {
    local feed_line=$(grep "src-git-full custom" "$1")
    local url=$(echo "$feed_line" | cut -d' ' -f3 | cut -d';' -f1)
    local branch=$(echo "$feed_line" | cut -d';' -f2)
    echo "$url $branch"
}

# Get custom feed URL and branch
read CUSTOM_FEED_URL CUSTOM_FEED_BRANCH <<< $(get_custom_feed_info "$SCRIPT_DIR/feeds.conf")
CUSTOM_FEED_NAME=$(basename "$CUSTOM_FEED_URL" .git)
CUSTOM_FEED_DIR="$HOME/$CUSTOM_FEED_NAME"

# Clone or update custom feed repository
if [ ! -d "$CUSTOM_FEED_DIR" ]; then
    git clone -b "$CUSTOM_FEED_BRANCH" "$CUSTOM_FEED_URL" "$CUSTOM_FEED_DIR"
else
    git -C "$CUSTOM_FEED_DIR" fetch
    git -C "$CUSTOM_FEED_DIR" checkout "$CUSTOM_FEED_BRANCH"
    git -C "$CUSTOM_FEED_DIR" pull origin "$CUSTOM_FEED_BRANCH"
fi

echo "CUSTOM_FEED_DIR: $CUSTOM_FEED_DIR"
echo "CUSTOM_FEED_BRANCH: $CUSTOM_FEED_BRANCH"

cd $OPENWRT_DIR

# Get current commit hashes
SCRIPT_COMMIT=$(get_latest_commit "$SCRIPT_DIR")
CUSTOM_FEED_COMMIT=$(get_latest_commit "$CUSTOM_FEED_DIR")

# Check if rebuild is necessary
REBUILD_NEEDED=false
if [ ! -f .last_build_info ] || \
   [ "$CUSTOM_FEED_COMMIT" != "$(grep CUSTOM_FEED_COMMIT .last_build_info | cut -d= -f2)" ]; then
    REBUILD_NEEDED=true
fi

# Check if only configuration has changed
CONFIG_CHANGED=false
if [ "$SCRIPT_COMMIT" != "$(grep SCRIPT_COMMIT .last_build_info | cut -d= -f2)" ]; then
    CONFIG_CHANGED=true
fi

cp $SCRIPT_DIR/feeds.conf $OPENWRT_DIR/feeds.conf

# Update and install feeds if needed
if [ "$REBUILD_NEEDED" = true ] || [ ! -f .feeds_updated ]; then
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    touch .feeds_updated
fi

# Copy configuration files
CONFIG_FILE="$ROUTERS_DIR/${ROUTER_TYPE}_config"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file for ${ROUTER_TYPE} not found!"
    echo "Available options:"
    for file in "$ROUTERS_DIR"/*_config; do
        basename "${file}" | sed 's/_config$//'
    done
    exit 1
fi
cp $CONFIG_FILE $OPENWRT_DIR/.config

make oldconfig

# Clean the build environment if rebuild is needed
if [ "$REBUILD_NEEDED" = true ]; then
    echo "Cleaning the build environment..."
    make clean
fi

# Install toolchain if needed
if [ "$REBUILD_NEEDED" = true ] || [ ! -f .toolchain_installed ]; then
    make -j$(nproc) toolchain/install
    touch .toolchain_installed
fi

# Run install_script.sh
$SCRIPT_DIR/install_script.sh "$SCRIPT_DIR" "$OPENWRT_DIR"

# Use make if needed, else use image builder
if [ "$REBUILD_NEEDED" = true ] || [ ! -f .firmware_built ] || [ .feeds_updated -nt .firmware_built ]; then
    # Estimate the total number of steps (you may need to adjust this)
    total_steps=$(make -n | grep -c '^')
    
    # Use pv to create a progress bar
    (
        make -j$(nproc) V=sc 2>&1 | tee make_logs.md | pv -l -s $total_steps > /dev/null
    )
    touch .firmware_built
elif [ "$CONFIG_CHANGED" = true ]; then
    echo "Configuration changed. Generating new sysupgrade.bin from existing binaries."
    # Run install_script.sh to prepare custom files
    $SCRIPT_DIR/install_script.sh "$SCRIPT_DIR" "$OPENWRT_DIR"

    # Get target and subtarget based on router type
    read TARGET SUBTARGET <<< $(get_target_subtarget "$ROUTER_TYPE")

    if [ "$TARGET" = "unknown" ] || [ "$SUBTARGET" = "unknown" ]; then
        echo "Error: Unknown router type $ROUTER_TYPE"
        exit 1
    fi

    # Get the profile name from the config file
    PROFILE=$(grep 'CONFIG_TARGET_PROFILE' $CONFIG_FILE | cut -d'"' -f2)

    # Get the list of packages from the config file
    PACKAGES=$(grep 'CONFIG_PACKAGE_' $CONFIG_FILE | grep '=y' | sed 's/CONFIG_PACKAGE_//g' | sed 's/=y//g' | tr '\n' ' ')

    # Use build_images.sh to create the firmware
    $SCRIPT_DIR/build_images.sh "${TARGET}/${SUBTARGET}" "$PROFILE" "$PACKAGES"
else
    echo "No changes detected. Using existing build."
fi

# Update last build info
echo "SCRIPT_COMMIT=$SCRIPT_COMMIT" > .last_build_info
echo "CUSTOM_FEED_COMMIT=$CUSTOM_FEED_COMMIT" >> .last_build_info

# Find and display the generated IPK files
echo "Finding the generated IPK files..."
TARGET_DIR="$OPENWRT_DIR/bin/packages"

# Array of file patterns to search for
file_patterns=(
    "libwebsockets*.ipk"
    "libwally*.ipk"
    "opennds*.ipk"
    "gltollgate*.ipk"
    "relaylink*.ipk"
    "signevent*.ipk"
)

# Flag to track if all files are found
all_files_found=true

# Loop through each file pattern
for pattern in "${file_patterns[@]}"; do
    # Find the file
    found_file=$(find "$TARGET_DIR" -type f -name "$pattern")
    
    # Check if the file was found
    if [ -z "$found_file" ]; then
        echo "Error: $pattern not found"
        all_files_found=false
    else
        echo "Found: $found_file"
    fi
done

# Exit with status 1 if any file wasn't found
if [ "$all_files_found" = false ]; then
    echo "One or more required IPK files were not found."
    exit 1
fi

echo "All required IPK files were found successfully."

# Find the sysupgrade.bin file
SYSUPGRADE_FILE=$(find "$OPENWRT_DIR/bin" -type f -name "*sysupgrade.bin")

# Check if file was found
if [ -z "$SYSUPGRADE_FILE" ]; then
    echo "No sysupgrade.bin file found."
    exit 1
fi

# Extract the base filename without extension
BASE_FILENAME=$(basename "$SYSUPGRADE_FILE" .bin)

# Create the new filename with commit hash
NEW_FILENAME="${BASE_FILENAME}_${SCRIPT_COMMIT}.bin"

# Copy the file to the destination directory with the new filename
cp "$SYSUPGRADE_FILE" "$HOME/TollGateNostrToolKit/binaries/$NEW_FILENAME"

# Check if copy was successful
if [ $? -eq 0 ]; then
    echo "Successfully copied $NEW_FILENAME to ~/TollGateNostrToolKit/binaries/."
else
    echo "Failed to copy file."
    exit 1
fi

echo "OpenWrt build completed successfully!"
