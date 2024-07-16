#!/bin/bash

# Exit on any error
# set -e

# Function to check if the script is run as root
if [ "$EUID" -eq 0 ]; then
  echo "Please do not run this script as root"
  exit 1
fi

# Function to check and run a script if it hasn't been run today
run_if_not_today() {
  local script_name=$1
  local timestamp_file="/tmp/$(basename $script_name).timestamp"

  if [ ! -f "$timestamp_file" ] || [ "$(date +%Y-%m-%d)" != "$(cat $timestamp_file)" ]; then
    echo "Running $script_name"
    ./$script_name
    if [ $? -eq 0 ]; then
      echo "$(date +%Y-%m-%d)" > "$timestamp_file"
    else
      echo "Error: $script_name failed to run."
      exit 1
    fi
  else
    echo "$script_name has already been run today"
  fi
}


##### MIPS Architecture  #####

run_if_not_today "setup_dependencies.sh"
run_if_not_today "clone_openwrt_sdk.sh"

run_if_not_today "build_toolchain.sh"
run_if_not_today "build_secp256k1_openwrt.sh"

run_if_not_today "compile_sign_event.sh"

##### Local Architecture #####

run_if_not_today "setup_x86_dependencies.sh"
run_if_not_today "compile_openssl_for_local.sh"
run_if_not_today "compile_secp256k1_for_local.sh"
run_if_not_today "compile_for_local.sh"

##### Generate checksum  #####

./generate_checksums.sh

# run_if_not_today "transfer_to_router.sh"

echo "All tasks completed successfully."

