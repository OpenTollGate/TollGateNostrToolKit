#!/bin/bash

# Directory containing the config files
SOURCE_DIR=~/TollGateNostrToolKit/routers

# OpenWrt config file path
OPENWRT_CONFIG=~/openwrt/.config

# Iterate over all files in the source directory
for config_file in "$SOURCE_DIR"/*_config; do
    if [ -f "$config_file" ]; then
        echo "Processing $config_file"
        
        # Overwrite OpenWrt .config with the current config file
        cp "$config_file" "$OPENWRT_CONFIG"
        
        # Change to the OpenWrt directory
        cd ~/openwrt
        
        # Run make oldconfig
        make oldconfig
        
        # Copy the updated config back to the original file
        cp "$OPENWRT_CONFIG" "$config_file"
        
        echo "Finished processing $config_file"
        echo "------------------------"
    fi
done

echo "All config files have been processed."
