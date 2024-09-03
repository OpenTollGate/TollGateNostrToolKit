#!/bin/bash

# Check if new_config argument is provided
if [ $# -eq 0 ]; then
    echo "Error: Please provide the new config filename as an argument."
    echo "Usage: $0 <new_config_filename>"
    exit 1
fi

# Path to the old config file
old_config="working/ath79_glar300m_config"

# New config file from command-line argument
new_config="$1"

# Check if the new_config file exists
if [ ! -f "$new_config" ]; then
    echo "Error: The file $new_config does not exist."
    exit 1
fi

# Merge the packages section from old config to new config
awk '/CONFIG_PACKAGE_/ || /CONFIG_TARGET_PROFILE/ || /CONFIG_DEFAULT_/ {
    gsub(/^# /, ""); 
    gsub(/ is not set$/, "=n"); 
    print
}' $old_config > merge_packages.tmp

# Append these settings to the new config
cat merge_packages.tmp >> $new_config

# Cleanup
rm merge_packages.tmp

echo "Configs merged. Verify with make menuconfig."
