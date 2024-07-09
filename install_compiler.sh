#!/bin/bash

# Define file paths and toolchain prefix
TOOLCHAIN_PREFIX="mips-linux-gnu"
SECP256K1_DIR="/tmp/secp256k1_mips"
INSTALL_DIR="/usr/local/mips-linux-gnu"

# Function to check if a command exists
function command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install packages only if they are not already installed
function install_packages_if_needed() {
    local packages=("$@")
    local to_install=()

    for package in "${packages[@]}"; do
        if ! dpkg -s "$package" &> /dev/null; then
            to_install+=("$package")
        fi
    done

    if [ ${#to_install[@]} -gt 0 ]; then
        echo "Installing: ${to_install[*]}"
        sudo apt-get install -y "${to_install[@]}"
    else
        echo "All packages are already installed."
    fi
}

# Function to update package lists if not updated today
function update_package_lists_if_needed() {
    local update_marker="/var/lib/apt/periodic/update-success-stamp"

    if [ ! -f "$update_marker" ] || [ "$(date +%Y-%m-%d -r "$update_marker")" != "$(date +%Y-%m-%d)" ]; then
        echo "Running apt-get update..."
        sudo apt-get update
    else
        echo "apt-get update has already been run today."
    fi
}

# Function to install the MIPS cross-compiler
function install_mips_cross_compiler() {
    echo "Checking for MIPS cross-compiler..."
    if ! command_exists ${TOOLCHAIN_PREFIX}-gcc || ! command_exists ${TOOLCHAIN_PREFIX}-g++; then
        echo "Installing MIPS cross-compiler..."
        install_packages_if_needed gcc-mips-linux-gnu g++-mips-linux-gnu
    else
        echo "MIPS cross-compiler is already installed."
    fi
}

# Function to compile secp256k1 for MIPS
function setup_secp256k1_mips() {
    echo "Checking if secp256k1 is already set up..."
    if [ ! -f "$INSTALL_DIR/lib/libsecp256k1.so" ]; then
        echo "Setting up secp256k1 for cross-compilation..."
        if [ ! -d "$SECP256K1_DIR" ]; then
            git clone https://github.com/bitcoin-core/secp256k1.git "$SECP256K1_DIR"
        fi
        cd "$SECP256K1_DIR"
        ./autogen.sh
        ./configure --host=${TOOLCHAIN_PREFIX} CC=${TOOLCHAIN_PREFIX}-gcc --prefix="$INSTALL_DIR" --enable-module-recovery
        make
        sudo make install
        cd -  # Return to the original directory
    else
        echo "secp256k1 is already installed."
    fi
}

# Main execution flow
update_package_lists_if_needed
install_mips_cross_compiler
setup_secp256k1_mips

echo "secp256k1 setup complete."

