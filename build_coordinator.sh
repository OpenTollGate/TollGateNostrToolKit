#!/bin/bash

# Exit on any error
# set -e

# Function to check if the script is run as root
if [ "$EUID" -eq 0 ]; then
  echo "Please do not run this script as root"
  exit 1
fi

./setup_dependencies.sh
./clone_openwrt_sdk.sh

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
