#!/bin/bash

# Define directories
LOCAL_INSTALL_DIR="$HOME/usr/local"
PARENT_DIR=".."
CURRENT_DIR=$(pwd)
SOURCE_FILE="$CURRENT_DIR/sign_event.c"
LOCAL_BINARY_DYNAMIC="$CURRENT_DIR/sign_event_local_dynamic"

# Function to compile for local architecture with dynamic linking (x86_64)
function compile_for_local_dynamic() {
    echo "Compiling for local architecture with dynamic linking..."
    gcc -O2 $SOURCE_FILE -o $LOCAL_BINARY_DYNAMIC \
        -I$PARENT_DIR/secp256k1_mips_architecture/include \
        -I$PARENT_DIR/secp256k1_mips_architecture \
        -I$LOCAL_INSTALL_DIR/include \
        -L$PARENT_DIR/secp256k1_mips_architecture/.libs \
        -L$LOCAL_INSTALL_DIR/lib \
        -lsecp256k1 -lssl -lcrypto

    if [ $? -eq 0 ]; then
        echo "Dynamic compilation successful: $LOCAL_BINARY_DYNAMIC"
    else
        echo "Failed to compile for local architecture with dynamic linking."
        exit 1
    fi
}

# Execute function
compile_for_local_dynamic
