#!/bin/bash

# Define directories and source file
PARENT_DIR=".."
CURRENT_DIR=$(pwd)
BINARIES_DIR="$CURRENT_DIR/binaries"

# Ensure binaries directory exists
mkdir -p $BINARIES_DIR

sudo apt-get install -y libtool

# Function to compile secp256k1 for local architecture (x86_64)
echo "Compiling secp256k1 for local architecture..."
cd $PARENT_DIR/secp256k1_mips_architecture
./autogen.sh
./configure --enable-static --disable-shared --enable-module-schnorrsig --enable-module-extrakeys
make clean
make -j$(nproc)

if [ $? -eq 0 ]; then
    echo "Compilation of secp256k1 successful for local architecture."
    # Copy the compiled library to binaries directory
    cp .libs/libsecp256k1.a $BINARIES_DIR/
    echo "Copied secp256k1 library to $BINARIES_DIR"
else
    echo "Failed to compile secp256k1 for local architecture."
    exit 1
fi
cd $CURRENT_DIR
