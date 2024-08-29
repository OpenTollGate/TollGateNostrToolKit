#!/bin/bash

# Path to the old and new config files
old_config="glar300m/.config"
new_config="archer_c7_v2/.config"

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
