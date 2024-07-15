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

./build_toolchain.sh
./build_secp256k1_openwrt.sh

./compile_sign_event.sh

./transfer_to_router.sh
