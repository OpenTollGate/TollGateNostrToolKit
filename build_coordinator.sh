#!/bin/bash

# Exit on any error
# set -e

# Function to check if the script is run as root
if [ "$EUID" -eq 0 ]; then
  echo "Please do not run this script as root"
  exit 1
fi

./setup_dependencies.sh


####################################
### BEGIN: Download openwrt repo ###
####################################

OPENWRT_DIR=~/openwrt
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

####################################
### END: Download openwrt repo   ###
### BEGIN: Build dependencies    ###
####################################

./build_toolchain.sh
./build_secp256k1_openwrt.sh

####################################
### END: Build dependencies      ###
### BEGIN: Compile program       ###
####################################

./compile_sign_event.sh

####################################
### BEGIN: Compile program       ###
### BEGIN: Transfer to router    ###
####################################

./transfer_to_router.sh
