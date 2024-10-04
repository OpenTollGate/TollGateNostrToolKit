#!/bin/bash

OPENWRT_DIR="$HOME/openwrt"

# Clone the OpenWrt repository if it doesn't exist
if [ ! -d "$OPENWRT_DIR" ]; then
  echo "Cloning OpenWrt repository..."
  git clone --depth 1 --branch v23.05.5 https://github.com/openwrt/openwrt.git $OPENWRT_DIR
  if [ $? -ne 0 ]; then
    echo "Failed to clone OpenWrt repository"
    exit 1
  fi
else
  echo "OpenWrt directory already exists."
fi
