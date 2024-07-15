#!/bin/bash

# Exit on any error
# set -e

# Function to check if the script is run as root
if [ "$EUID" -eq 0 ]; then
  echo "Please do not run this script as root"
  exit 1
fi

# Check if the script has been run today
LAST_UPDATE_FILE="/tmp/last_update_check"

# Update system if it hasn't been updated today
if [ ! -f "$LAST_UPDATE_FILE" ] || [ "$(date +%Y-%m-%d)" != "$(cat $LAST_UPDATE_FILE)" ]; then
  sudo apt-get update
  echo "$(date +%Y-%m-%d)" > "$LAST_UPDATE_FILE"
else
  echo "System already updated today"
fi

# Install necessary dependencies only if they are not already installed
declare -a packages=("build-essential" "libncurses5-dev" "libncursesw5-dev" "git" "python3" "rsync" "file" "wget")

for pkg in "${packages[@]}"; do
  if ! dpkg -l | grep -qw "$pkg"; then
    sudo apt-get install -y "$pkg"
  else
    echo "$pkg is already installed"
  fi
done

# Variables
OPENWRT_DIR=~/openwrt
CONFIG_FILE=".config"
FEEDS_FILE="feeds.conf"
PACKAGE_NAME="secp256k1"
TARGET_DIR="bin/packages/*/*"

# Clone the OpenWrt repository if it doesn't exist
if [ ! -d "$OPENWRT_DIR" ]; then
  echo "Cloning OpenWrt repository..."
  git clone --depth 1 --branch v23.05.3 https://github.com/openwrt/openwrt.git $OPENWRT_DIR
  if [ $? -ne 0 ]; then
    echo "Failed to clone OpenWrt repository"
    exit 1
  fi
else
  echo "OpenWrt directory already exists."
fi

# Navigate to the existing OpenWrt build directory
cd $OPENWRT_DIR


# Verify if secp256k1 is set to true in .config
if ! grep -q "^CONFIG_PACKAGE_secp256k1=y" .config; then
  echo "Error: secp256k1 is not set to true in the .config file."
  exit 1
fi

# Update and install all feeds
./scripts/feeds update -a

# Verify if secp256k1 is set to true in .config
if ! grep -q "^CONFIG_PACKAGE_secp256k1=y" .config; then
  echo "After update, Error: secp256k1 is not set to true in the .config file."
  exit 1
fi

./scripts/feeds install -a

# Verify if secp256k1 is set to true in .config
if ! grep -q "^CONFIG_PACKAGE_secp256k1=y" .config; then
  echo "After install, Error: secp256k1 is not set to true in the .config file."
  exit 1
fi


make -j$(nproc) toolchain/install
if [ $? -ne 0 ]; then
    echo "Toolchain install failed"
    exit 1
fi

# Verify if secp256k1 is set to true in .config
if ! grep -q "^CONFIG_PACKAGE_secp256k1=y" .config; then
  echo "After toolchain install, Error: secp256k1 is not set to true in the .config file."
  exit 1
fi


# Copy configuration files
cp ~/nostrSigner/.config $OPENWRT_DIR/.config
cp ~/nostrSigner/feeds.conf $OPENWRT_DIR/feeds.conf



# Update the custom feed
echo "Updating custom feed..."
./scripts/feeds update custom

# Verify if secp256k1 is set to true in .config
if ! grep -q "^CONFIG_PACKAGE_secp256k1=y" .config; then
  echo "After custom update, Error: secp256k1 is not set to true in the .config file."
  exit 1
fi


# Install the secp256k1 package from the custom feed
echo "Installing secp256k1 package from custom feed..."
./scripts/feeds install $PACKAGE_NAME

# Check for feed install errors
if [ $? -ne 0 ]; then
    echo "Feeds install failed"
    exit 1
fi

# Verify if secp256k1 is set to true in .config
if ! grep -q "^CONFIG_PACKAGE_secp256k1=y" .config; then
  echo "After custom install, Error: secp256k1 is not set to true in the .config file."
  exit 1
fi



# Build the specific package
echo "Building the $PACKAGE_NAME package..."
make -j$(nproc) package/$PACKAGE_NAME/download V=s
if [ $? -ne 0 ]; then
    echo "$PACKAGE_NAME download failed."
    exit 1
fi

make -j$(nproc) package/$PACKAGE_NAME/check V=s
if [ $? -ne 0 ]; then
    echo "$PACKAGE_NAME check failed."
    exit 1
fi

make -j$(nproc) package/$PACKAGE_NAME/compile V=s
if [ $? -ne 0 ]; then
    echo "$PACKAGE_NAME compile failed."
    exit 1
fi


# Verify if secp256k1 is set to true in .config
if ! grep -q "^CONFIG_PACKAGE_secp256k1=y" .config; then
  echo "After compile, Error: secp256k1 is not set to true in the .config file."
  exit 1
fi

# Build the firmware
echo "Building the firmware..."
make -j$(nproc) V=s
if [ $? -ne 0 ]; then
    echo "Firmware build failed."
    exit 1
fi

# Find and display the generated IPK file
echo "Finding the generated IPK file..."
find $TARGET_DIR -name "*$PACKAGE_NAME*.ipk"

echo "OpenWrt build completed successfully!"

