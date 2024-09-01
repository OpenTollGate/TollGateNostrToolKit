#!/bin/bash

# Define directories
PARENT_DIR=".."
CURRENT_DIR=$(pwd)
BINARIES_DIR="$CURRENT_DIR/binaries"

# Ensure binaries directory exists
mkdir -p $BINARIES_DIR

# URLs of the dependencies
OPENSSL_URL="https://github.com/openssl/openssl.git"
LIBCRYPTO_URL="https://github.com/libcrypto/libcrypto.git"
SECP256K1_URL="https://github.com/bitcoin-core/secp256k1.git"

# Clone the dependencies
function clone_dependencies() {
    echo "Cloning dependencies..."
    cd $PARENT_DIR

    if [ ! -d "openssl" ]; then
        git clone --depth 1 $OPENSSL_URL openssl
    else
        cd openssl
        git pull
        cd ..
    fi

    if [ ! -d "libcrypto" ]; then
        git clone --depth 1 $LIBCRYPTO_URL libcrypto
    else
        cd libcrypto
        git pull
        cd ..
    fi

    if [ ! -d "secp256k1_mips_architecture" ]; then
        git clone --depth 1 $SECP256K1_URL secp256k1_mips_architecture
    else
        cd secp256k1_mips_architecture
        git pull
        cd ..
    fi

    cd $CURRENT_DIR
}

# Execute function
clone_dependencies
