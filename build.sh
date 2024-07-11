#!/bin/bash

# Ensure that the uBitcoin library path is correctly included
PARENT_DIR=".."
U_BITCOIN_DIR="$PARENT_DIR/uBitcoin/src"

# Define the installation directories and compiler settings
LOCAL_INSTALL_DIR="$HOME/usr/local"
MIPS_INSTALL_DIR="$HOME/usr/local/mips-linux-gnu"
TOOLCHAIN_PREFIX="mips-linux-gnu"
CURRENT_DIR=$(pwd)

./install_compiler.sh

# Create installation directories if they don't exist
mkdir -p $LOCAL_INSTALL_DIR
mkdir -p $MIPS_INSTALL_DIR

# Source file and output binaries
SOURCE_FILE="$CURRENT_DIR/sign_event.c"
LOCAL_BINARY="$CURRENT_DIR/sign_event_local"
LOCAL_BINARY_DYNAMIC="$CURRENT_DIR/sign_event_local_dynamic"
MIPS_BINARY="$CURRENT_DIR/sign_event_mips"
MIPS_BINARY_DYNAMIC="$CURRENT_DIR/sign_event_mips_dynamic"
CHECKSUM_FILE="$CURRENT_DIR/checksums.json"

# URL of the uBitcoin dependency
UBITCOIN_URL="https://github.com/uBitcoin/uBitcoin.git"

# Clone the dependencies
function clone_dependencies() {
    echo "Cloning dependencies..."
    cd $PARENT_DIR

    if [ ! -d "uBitcoin" ]; then
        git clone --depth 1 $UBITCOIN_URL uBitcoin
    else
        cd uBitcoin
        git pull
        cd ..
    fi

    cd $CURRENT_DIR
}

# Function to clean up build directories
function clean_build_directories() {
    echo "Cleaning up build directories..."
    cd $PARENT_DIR/uBitcoin
    make clean || true
    cd $CURRENT_DIR
}

# Function to compile for MIPS architecture with dynamic linking
function compile_for_mips_dynamic() {
    echo "Compiling for MIPS architecture with dynamic linking..."
    $TOOLCHAIN_PREFIX-gcc -march=mips32r2 -O2 $SOURCE_FILE -o $MIPS_BINARY_DYNAMIC \
                          -I$U_BITCOIN_DIR

    if [ $? -eq 0 ]; then
        echo "Dynamic compilation successful: $MIPS_BINARY_DYNAMIC"
    else
        echo "Failed to compile for MIPS architecture with dynamic linking."
        exit 1
    fi
}

# Function to compile for MIPS architecture
function compile_for_mips() {
    echo "Compiling for MIPS architecture..."
    
    $TOOLCHAIN_PREFIX-gcc -march=mips32r2 -O2 $SOURCE_FILE -o $MIPS_BINARY \
                          -I$U_BITCOIN_DIR \
                          -static

    if [ $? -eq 0 ]; then
        echo "Compilation successful: $MIPS_BINARY"
    else
        echo "Failed to compile for MIPS architecture."
        exit 1
    fi
}

# Function to generate checksums and file sizes, and save them in a JSON file
function generate_checksums() {
    echo "Generating checksums and file sizes..."
    declare -A binaries=(
        ["mips_binary"]=$MIPS_BINARY
        ["mips_binary_dynamic"]=$MIPS_BINARY_DYNAMIC
    )
    
    checksums="{\n"
    for key in "${!binaries[@]}"; do
        binary="${binaries[$key]}"
        if [ -f "$binary" ]; then
            checksum=$(sha256sum $binary | awk '{print $1}')
            size=$(stat --format="%s" $binary)
            checksums+="  \"${key}_checksum\": \"$checksum\",\n"
            checksums+="  \"${key}_size\": \"$size\",\n"
        fi
    done
    checksums="${checksums%,\n}\n}"  # Remove the last comma and add the closing brace
    
    echo -e "$checksums" > $CHECKSUM_FILE
    echo "Checksums and file sizes saved to $CHECKSUM_FILE"
}

# Main execution flow
clone_dependencies
clean_build_directories

# Compile MIPS binaries
compile_for_mips
compile_for_mips_dynamic

generate_checksums

echo "All compilations and checksum generation completed successfully."

