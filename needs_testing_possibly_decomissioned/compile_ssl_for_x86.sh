#!/bin/bash

# Define directories
LOCAL_INSTALL_DIR="$HOME/usr/local"
PARENT_DIR=".."
CURRENT_DIR=$(pwd)

# Function to compile OpenSSL for local architecture (x86_64)
function compile_openssl_for_local() {
    echo "Compiling OpenSSL for local architecture..."
    cd $PARENT_DIR/openssl
    ./config --prefix=$LOCAL_INSTALL_DIR no-shared no-asm
    make clean
    make -j$(nproc)
    make install

    if [ $? -eq 0 ]; then
        echo "Compilation of OpenSSL successful for local architecture."
    else
        echo "Failed to compile OpenSSL for local architecture."
        exit 1
    fi
    cd $CURRENT_DIR
}

# Execute function
compile_openssl_for_local
