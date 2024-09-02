#!/bin/bash

# Check if the script has been run today
LAST_UPDATE_FILE="/tmp/last_update_check"

# Update system if it hasn't been updated today
if [ ! -f "$LAST_UPDATE_FILE" ] || [ "$(date +%Y-%m-%d)" != "$(cat $LAST_UPDATE_FILE)" ]; then
  sudo apt-get update
  echo "$(date +%Y-%m-%d)" > "$LAST_UPDATE_FILE"
else
  echo "System already updated today"
fi

# List of necessary dependencies
declare -a packages=(
  "build-essential" "ccache" "fastjar" "file" "g++" "gawk" "gettext" "git"
  "libelf-dev" "libncurses-dev" "libssl-dev" "python3" "python3-dev"
  "unzip" "wget" "python3-setuptools" "rsync" "subversion" "swig" "time"
  "xsltproc" "zlib1g-dev" "libexpat1-dev" "libpython3-dev" "libzstd-dev"
  "python3.12-dev" "javascript-common" "libapr1t64" "libaprutil1t64"
  "libhiredis1.1.0" "libjs-jquery" "libjs-sphinxdoc" "libjs-underscore"
  "libserf-1-1" "libsvn1" "libutf8proc3" "jq"
)

# Install necessary dependencies only if they are not already installed
for pkg in "${packages[@]}"; do
  if ! dpkg -l | grep -qw "$pkg"; then
    sudo apt-get install -y "$pkg"
  else
    echo "$pkg is already installed"
  fi
done

# Setup OpenWrt Image Builder
OPENWRT_VERSION="23.05.4"
TARGET="ath79/nand"
BUILDER_DIR="openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET/\//-}.Linux-x86_64"
BUILDER_ARCHIVE="${BUILDER_DIR}.tar.xz"

if [ ! -d "$BUILDER_DIR" ]; then
  echo "Downloading OpenWrt Image Builder..."
  wget "https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/${TARGET}/${BUILDER_ARCHIVE}"
  
  echo "Extracting OpenWrt Image Builder..."
  tar xJf "$BUILDER_ARCHIVE"
  
  echo "Cleaning up..."
  rm "$BUILDER_ARCHIVE"
else
  echo "OpenWrt Image Builder already set up"
fi

echo "Setup complete!"
