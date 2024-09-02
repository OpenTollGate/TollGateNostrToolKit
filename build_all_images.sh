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

# Extract common packages
common_packages=$(echo "$json_content" | jq -r '.common.packages')

# Create binaries directory if it doesn't exist
BINARIES_DIR="./binaries"
mkdir -p "$BINARIES_DIR"

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

    # Setup dependencies for this target
    ./setup_dependencies.sh "$target"

    # Call build_images.sh
    ./build_images.sh "$target" "$profile" "$all_packages"

    echo "----------------------------------------"
done

# After all builds are complete, find and copy all sysupgrade files
echo "Copying all sysupgrade files to $BINARIES_DIR"
# TODO: Be sure not to copy the sysupgrade.bin from the tmp file. It needs to be from bin
exit 1
find . -regex ".*openwrt-.*-sysupgrade.bin" -exec cp {} "$BINARIES_DIR" \;

# Check if any files were copied
if [ "$(ls -A "$BINARIES_DIR")" ]; then
    echo "Sysupgrade files have been copied to $BINARIES_DIR"
else
    echo "No sysupgrade files found to copy"
fi
