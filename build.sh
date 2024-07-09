#!/bin/bash

# Define the installation directories and compiler settings
LOCAL_INSTALL_DIR="/usr/local"
MIPS_INSTALL_DIR="/usr/local/mips-linux-gnu"
TOOLCHAIN_PREFIX="mips-linux-gnu"

# Source file and output binaries
SOURCE_FILE="sign_event.c"
LOCAL_BINARY="sign_event_local"
MIPS_BINARY="sign_event_mips"
CHECKSUM_FILE="checksums.json"

# Function to compile for local architecture (x86_64)
function compile_for_local() {
    echo "Compiling for local architecture..."
    gcc $SOURCE_FILE -o $LOCAL_BINARY \
        -I$LOCAL_INSTALL_DIR/include -L$LOCAL_INSTALL_DIR/lib \
        -lsecp256k1 -lssl -lcrypto

    if [ $? -eq 0 ]; then
        echo "Compilation successful: $LOCAL_BINARY"
    else
        echo "Failed to compile for local architecture."
        exit 1
    fi
}

# Function to compile for MIPS architecture
function compile_for_mips() {
    echo "Compiling for MIPS architecture..."
    $TOOLCHAIN_PREFIX-gcc $SOURCE_FILE -o $MIPS_BINARY \
        -I$MIPS_INSTALL_DIR/include -L$MIPS_INSTALL_DIR/lib \
        -lsecp256k1 -lssl -lcrypto

    if [ $? -eq 0 ]; then
        echo "Compilation successful: $MIPS_BINARY"
    else
        echo "Failed to compile for MIPS architecture."
        exit 1
    fi
}

# Function to generate checksums and save them in a JSON file
function generate_checksums() {
    echo "Generating checksums..."
    local_checksum=$(sha256sum $LOCAL_BINARY | awk '{print $1}')
    mips_checksum=$(sha256sum $MIPS_BINARY | awk '{print $1}')

    echo -e "{\n  \"local_binary_checksum\": \"$local_checksum\",\n  \"mips_binary_checksum\": \"$mips_checksum\"\n}" > $CHECKSUM_FILE
    echo "Checksums saved to $CHECKSUM_FILE"
}

# Main execution flow
compile_for_local
compile_for_mips
generate_checksums

echo "All compilations and checksum generation completed successfully."

