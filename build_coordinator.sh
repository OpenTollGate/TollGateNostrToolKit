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


# x86 build
# ./setup_x86_dependencies.sh
# ./clean_x86_build_directories.sh
# ./compile_secp_for_mips.sh
# ./compile_ssl_for_x86.sh
# ./compile_secp_for_local.sh
# ./compile_openssl_for_mips.sh
# ./compile_secp256k1_for_mips.sh
# ./compile_for_local_dynamic.sh
