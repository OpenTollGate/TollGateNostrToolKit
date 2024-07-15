#!/bin/bash

# Define directories
LOCAL_INSTALL_DIR="$HOME/usr/local"
PARENT_DIR=".."
CURRENT_DIR=$(pwd)
SOURCE_FILE="$CURRENT_DIR/sign_event.c"
LOCAL_BINARY="$CURRENT_DIR/sign_event_local"

# Function to find the library paths
function find_lib_paths() {
    local base_dir=$1
    LIBSSL_PATH=$(find $base_dir -name "libssl.a" | head -n 1)
    LIBCRYPTO_PATH=$(find $base_dir -name "libcrypto.a" | head -n 1)

    if [ -z "$LIBSSL_PATH" ] || [ -z "$LIBCRYPTO_PATH" ]; then
        echo "Static libraries not found in $base_dir"
        exit 1
    fi
}

# Function to compile for local architecture (x86_64)
function compile_for_local() {
    echo "Compiling for local architecture..."
    find_lib_paths $LOCAL_INSTALL_DIR

    gcc -O2 $SOURCE_FILE -o $LOCAL_BINARY \
        -I$PARENT_DIR/secp256k1_mips_architecture/include \
        -I$LOCAL_INSTALL_DIR/include \
        -L$PARENT_DIR/secp256k1_mips_architecture/.libs \
        -L$(dirname $LIBSSL_PATH) \
        $PARENT_DIR/secp256k1_mips_architecture/.libs/libsecp256k1.a $LIBSSL_PATH $LIBCRYPTO_PATH

    if [ $? -eq 0 ]; then
        echo "Compilation successful: $LOCAL_BINARY"
    else
        echo "Failed to compile for local architecture."
        exit 1
    fi
}

# Execute function
compile_for_local
