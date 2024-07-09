#!/bin/bash

# Define the installation directories and compiler settings
LOCAL_INSTALL_DIR="/usr/local"
MIPS_INSTALL_DIR="/usr/local/mips-linux-gnu"
TOOLCHAIN_PREFIX="mips-linux-gnu"

# Source file and output binaries
SOURCE_FILE="sign_event.c"
LOCAL_BINARY="sign_event_local"
MIPS_BINARY="sign_event_mips"

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

# Main execution flow
compile_for_local
compile_for_mips

echo "All compilations completed successfully."
