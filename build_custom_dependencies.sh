#!/bin/bash

set -e

SCRIPT_DIR="$HOME/TollGateNostrToolKit"
ROUTERS_DIR="$SCRIPT_DIR/routers"

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <router_type>"
    echo "Available options:"
    for file in "$ROUTERS_DIR"/*_config; do
        basename "${file}" | sed 's/_config$//'
    done
    exit 1
fi

ROUTER_TYPE=$1

OPENWRT_DIR="$HOME/openwrt"
cd $OPENWRT_DIR

cp $SCRIPT_DIR/feeds.conf $OPENWRT_DIR/feeds.conf

# Update the custom feed
echo "Updating custom feed..."
./scripts/feeds update -a

# Install the dependencies from the custom feed
echo "Installing dependencies from custom feed..."
./scripts/feeds install -a

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

# Check for feed install errors
if [ $? -ne 0 ]; then
    echo "Feeds install failed"
    exit 1
fi

# Clean the build environment
echo "Cleaning the build environment..."
make clean

# Install the toolchain
echo "Installing toolchain..."
make -j$(nproc) toolchain/install
if [ $? -ne 0 ]; then
    echo "Toolchain install failed"
    exit 1
fi

echo "Build with dependencies before using them..."
make -j$(nproc) V=sc > make_logs.md 2>&1
if [ $? -ne 0 ]; then
   echo "Firmware build failed."
   exit 1
fi



# Find and display the generated IPK files
echo "Finding the generated IPK files..."
TARGET_DIR="$OPENWRT_DIR/bin/packages"

# Array of file patterns to search for
file_patterns=(
    "libwebsockets*.ipk"
    "libwally*.ipk"
    "nodogsplash*.ipk"
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

# Copy the file to the destination directory
cp "$SYSUPGRADE_FILE" ~/TollGateNostrToolKit/binaries/.

# Check if copy was successful
if [ $? -eq 0 ]; then
    echo "Successfully copied $(basename "$SYSUPGRADE_FILE") to ~/TollGateNostrToolKit/binaries/."
else
    echo "Failed to copy file."
    exit 1
fi

echo "OpenWrt build completed successfully!"
