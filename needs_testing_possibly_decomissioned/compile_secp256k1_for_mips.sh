#!/bin/bash

# Define directories and compiler settings
TOOLCHAIN_PREFIX="mips-linux-gnu"
PARENT_DIR=".."
CURRENT_DIR=$(pwd)

# Function to compile secp256k1 for MIPS architecture
function compile_secp256k1_for_mips() {
    echo "Compiling secp256k1 for MIPS architecture..."
    cd $PARENT_DIR/secp256k1_mips_architecture
    ./autogen.sh
    ./configure --host=mips-linux-gnu --enable-static --disable-shared --enable-module-schnorrsig --enable-module-extrakeys CC="$TOOLCHAIN_PREFIX-gcc -march=mips32r2"
    make clean
    make -j$(nproc)

    if [ $? -eq 0 ]; then
        echo "Compilation of secp256k1 successful for MIPS."
    else
        echo "Failed to compile secp256k1 for MIPS architecture."
        exit 1
    fi
    cd $CURRENT_DIR
}

# Execute function
compile_secp256k1_for_mips
