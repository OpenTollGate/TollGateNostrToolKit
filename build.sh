#!/bin/bash

# Define the installation directories and compiler settings
LOCAL_INSTALL_DIR="/usr/local"
MIPS_INSTALL_DIR="/usr/local/mips-linux-gnu"
TOOLCHAIN_PREFIX="mips-linux-gnu"
PARENT_DIR=".."
CURRENT_DIR=$(pwd)

# Source file and output binaries
SOURCE_FILE="$CURRENT_DIR/sign_event.c"
LOCAL_BINARY="$CURRENT_DIR/sign_event_local"
MIPS_BINARY="$CURRENT_DIR/sign_event_mips"
CHECKSUM_FILE="$CURRENT_DIR/checksums.json"

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

# Function to compile OpenSSL for MIPS architecture
function compile_openssl_for_mips() {
    echo "Compiling OpenSSL for MIPS architecture..."
    cd $PARENT_DIR/openssl
    ./Configure linux-mips32 --prefix=$MIPS_INSTALL_DIR no-shared no-asm \
        CC=$TOOLCHAIN_PREFIX-gcc AR=$TOOLCHAIN_PREFIX-ar \
        RANLIB=$TOOLCHAIN_PREFIX-ranlib LD=$TOOLCHAIN_PREFIX-ld
    make
    make install

    if [ $? -eq 0 ]; then
        echo "Compilation of OpenSSL successful for MIPS."
    else
        echo "Failed to compile OpenSSL for MIPS architecture."
        exit 1
    fi
    cd $CURRENT_DIR
}

# Function to compile secp256k1 for MIPS architecture
function compile_secp256k1_for_mips() {
    echo "Compiling secp256k1 for MIPS architecture..."
    cd $PARENT_DIR/secp256k1_mips_architecture
    ./autogen.sh
    ./configure --host=mips-linux-gnu --enable-static --disable-shared \
        CC=$TOOLCHAIN_PREFIX-gcc
    make

    if [ $? -eq 0 ]; then
        echo "Compilation of secp256k1 successful for MIPS."
    else
        echo "Failed to compile secp256k1 for MIPS architecture."
        exit 1
    fi
    cd $CURRENT_DIR
}

# Function to compile for MIPS architecture
function compile_for_mips() {
    echo "Compiling for MIPS architecture..."
    $TOOLCHAIN_PREFIX-gcc $SOURCE_FILE -o $MIPS_BINARY \
        -I$PARENT_DIR/secp256k1_mips_architecture/include -L$PARENT_DIR/secp256k1_mips_architecture/.libs \
        -I$MIPS_INSTALL_DIR/include -L$MIPS_INSTALL_DIR/lib \
        -lsecp256k1 -lssl -lcrypto -static

    if [ $? -eq 0 ]; then
        echo "Compilation successful: $MIPS_BINARY"
    else
        echo "Failed to compile for MIPS architecture."
        exit 1
    fi
}

# Function to generate checksums and save them in a JSON file
function generate_checksums() {
    echo "Generating checksums..."
    local_checksum=$(sha256sum $LOCAL_BINARY | awk '{print $1}')
    mips_checksum=$(sha256sum $MIPS_BINARY | awk '{print $1}')

    echo -e "{\n  \"local_binary_checksum\": \"$local_checksum\",\n  \"mips_binary_checksum\": \"$mips_checksum\"\n}" > $CHECKSUM_FILE
    echo "Checksums saved to $CHECKSUM_FILE"
}

# Main execution flow
clone_dependencies
compile_for_local
compile_openssl_for_mips
compile_secp256k1_for_mips
compile_for_mips
generate_checksums

echo "All compilations and checksum generation completed successfully."

