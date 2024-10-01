#!/bin/bash

# Check if correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <openwrt_directory> [soft|normal|hard|nuclear]"
    exit 1
fi

# Set variables
OPENWRT_DIR="$1"
clean_level="$2"

# Check if the provided directory exists
if [ ! -d "$OPENWRT_DIR" ]; then
    echo "Error: Directory $OPENWRT_DIR does not exist."
    exit 1
fi

# Change to the OpenWrt directory
cd "$OPENWRT_DIR" || exit 1

# Function to run make commands
run_make() {
    make "$@"
}

# Cleaning function
perform_clean() {
    case "$clean_level" in
        "soft")
            echo "Performing soft clean..."
            run_make clean
            ;;
        "normal")
            echo "Performing normal clean..."
            run_make distclean
            ;;
        "hard")
            echo "Performing hard clean..."
            run_make distclean
            rm -rf build_dir staging_dir tmp
            ./scripts/feeds clean
            rm -rf feeds
            ./scripts/feeds update -a
            ./scripts/feeds install -a
            ;;
        "nuclear")
            echo "Performing nuclear clean (everything except downloads)..."
            run_make distclean
            rm -rf build_dir staging_dir tmp toolchain .config feeds
            ./scripts/feeds clean
            ./scripts/feeds update -a
            ./scripts/feeds install -a
            ;;
        *)
            echo "Invalid clean level. Use: soft, normal, hard, or nuclear"
            exit 1
            ;;
    esac
}

# Perform the cleaning
perform_clean

echo "Clean complete. Don't forget to reconfigure with 'make menuconfig' if necessary."
