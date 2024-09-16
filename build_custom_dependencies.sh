#!/bin/bash

set -e

# Define necessary variables
SCRIPT_DIR="$HOME/TollGateNostrToolKit"
OPENWRT_DIR="$HOME/openwrt"
ROUTERS_DIR="$SCRIPT_DIR/routers"

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


cd $OPENWRT_DIR

cp $SCRIPT_DIR/feeds.conf $OPENWRT_DIR/feeds.conf

# After updating and installing feeds
if [ ! -f .feeds_updated ]; then
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

# Check for feed install errors
if [ $? -ne 0 ]; then
    echo "Feeds install failed"
    exit 1
fi

# Clean the build environment
echo "Cleaning the build environment..."
make clean

# Before running make
if [ ! -f .toolchain_installed ]; then
  make -j$(nproc) toolchain/install
  touch .toolchain_installed
fi

# Run install_script.sh here
$SCRIPT_DIR/install_script.sh "$SCRIPT_DIR" "$OPENWRT_DIR"

# Only run make if necessary
if [ ! -f .firmware_built ] || [ .feeds_updated -nt .firmware_built ]; then
  make -j$(nproc) V=sc > make_logs.md 2>&1
  touch .firmware_built
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
