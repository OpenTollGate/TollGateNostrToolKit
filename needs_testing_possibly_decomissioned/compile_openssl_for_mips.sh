#!/bin/bash

# Define directories and compiler settings
MIPS_INSTALL_DIR="$HOME/usr/local/mips-linux-gnu"
TOOLCHAIN_PREFIX="mips-linux-gnu"
PARENT_DIR=".."
CURRENT_DIR=$(pwd)

# Function to compile OpenSSL for MIPS architecture
function compile_openssl_for_mips() {
    echo "Compiling OpenSSL for MIPS architecture..."
    cd $PARENT_DIR/openssl
    ./Configure linux-mips32 --prefix=$MIPS_INSTALL_DIR no-shared no-asm \
        CC="$TOOLCHAIN_PREFIX-gcc -march=mips32r2" AR=$TOOLCHAIN_PREFIX-ar \
        RANLIB=$TOOLCHAIN_PREFIX-ranlib LD=$TOOLCHAIN_PREFIX-ld
    make clean
    make -j$(nproc)
    make install

    if [ $? -eq 0 ]; then
        echo "Compilation of OpenSSL successful for MIPS."
    else
        echo "Failed to compile OpenSSL for MIPS architecture."
        exit 1
    fi
    cd $CURRENT_DIR
}

# Execute function
compile_openssl_for_mips
