#!/bin/bash

# Define directories
LOCAL_INSTALL_DIR="$HOME/usr/local"
PARENT_DIR=".."
CURRENT_DIR=$(pwd)
BINARIES_DIR="$CURRENT_DIR/binaries"

# Ensure binaries directory exists
mkdir -p $BINARIES_DIR

# Function to compile OpenSSL for local architecture (x86_64)
echo "Compiling OpenSSL for local architecture..."
cd $PARENT_DIR/openssl
./config --prefix=$LOCAL_INSTALL_DIR no-shared no-asm
make clean
make -j$(nproc)
make install

if [ $? -eq 0 ]; then
    echo "Compilation of OpenSSL successful for local architecture."
    # Copy the compiled libraries to binaries directory
    cp $LOCAL_INSTALL_DIR/lib/libssl.a $BINARIES_DIR/
    cp $LOCAL_INSTALL_DIR/lib/libcrypto.a $BINARIES_DIR/
    echo "Copied OpenSSL libraries to $BINARIES_DIR"
else
    echo "Failed to compile OpenSSL for local architecture."
    exit 1
fi
cd $CURRENT_DIR
