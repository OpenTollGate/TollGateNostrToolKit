#!/bin/bash

# Function to combine packages
combine_packages() {
    local device_packages="$1"
    local common_packages="$2"
    echo "$device_packages $common_packages" | tr ' ' '\n' | sort -u | tr '\n' ' '
}

# Read the JSON file
json_file="build_image_arguments.json"
json_content=$(cat "$json_file")

./setup_dependencies.sh ath79/generic
./setup_dependencies.sh ipq806x/generic
./setup_dependencies.sh ramips/mt7620
./setup_dependencies.sh ramips/mt76x8

# Extract common packages
common_packages=$(echo "$json_content" | jq -r '.common.packages')

# Iterate over each device
for device in $(echo "$json_content" | jq -r 'keys[] | select(. != "common")')
do
    target=$(echo "$json_content" | jq -r ".$device.target")
    profile=$(echo "$json_content" | jq -r ".$device.profile")
    device_packages=$(echo "$json_content" | jq -r ".$device.packages")

    # Combine packages
    all_packages=$(combine_packages "$device_packages" "$common_packages")

    echo "Building image for $device..."
    echo "Target: $target"
    echo "Profile: $profile"
    echo "Packages: $all_packages"

    # Call build_images.sh
    ./build_images.sh "$target" "$profile" "$all_packages"

    echo "----------------------------------------"
done
