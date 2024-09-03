#!/bin/bash

# Check if a filename argument is provided
if [ $# -eq 0 ]; then
    echo "Error: Please provide a name for the new config file."
    echo "Usage: $0 <new_config_filename>"
    exit 1
fi

# Set paths
SOURCE_CONFIG=~/TollGateNostrToolKit/routers/working/ath79_glar300m_config
OPENWRT_CONFIG=~/openwrt/.config
NEW_CONFIG=~/TollGateNostrToolKit/routers/$1

# Copy the ath79_glar300m_config to OpenWrt .config
echo "Copying ath79_glar300m_config to OpenWrt .config..."
cp "$SOURCE_CONFIG" "$OPENWRT_CONFIG"

# Change to the OpenWrt directory
cd ~/openwrt

# Run make menuconfig
echo "Running make menuconfig. Please make your selections..."
make menuconfig

# Copy the updated .config back to TollGateNostrToolKit/routers with the new name
echo "Copying updated config back to TollGateNostrToolKit/routers as $1..."
cp "$OPENWRT_CONFIG" "$NEW_CONFIG"

echo "Process completed. New config file saved as $NEW_CONFIG"
