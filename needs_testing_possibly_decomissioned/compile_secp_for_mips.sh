#!/bin/bash

# Define directories
PARENT_DIR=".."
CURRENT_DIR=$(pwd)

# Function to compile secp256k1 for local architecture (x86_64)
function compile_secp256k1_for_local() {
    echo "Compiling secp256k1 for local architecture..."
    cd $PARENT_DIR/secp256k1_mips_architecture
    ./autogen.sh
    ./configure --enable-static --disable-shared --enable-module-schnorrsig --enable-module-extrakeys
    make clean
    make -j$(nproc)

    if [ $? -eq 0 ]; then
        echo "Compilation of secp256k1 successful for local architecture."
    else
        echo "Failed to compile secp256k1 for local architecture."
        exit 1
    fi
    cd $CURRENT_DIR
}

# Execute function
compile_secp256k1_for_local
