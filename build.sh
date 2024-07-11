#!/bin/bash

# Define the installation directories and compiler settings
LOCAL_INSTALL_DIR="$HOME/usr/local"
MIPS_INSTALL_DIR="$HOME/usr/local/mips-linux-gnu"
TOOLCHAIN_PREFIX="mips-linux-gnu"
PARENT_DIR=".."
CURRENT_DIR=$(pwd)

./install_compiler.sh

# Create installation directories if they don't exist
mkdir -p $LOCAL_INSTALL_DIR
mkdir -p $MIPS_INSTALL_DIR

# Source file and output binaries
SOURCE_FILE="$CURRENT_DIR/sign_event.c"
LOCAL_BINARY="$CURRENT_DIR/sign_event_local"
LOCAL_BINARY_DYNAMIC="$CURRENT_DIR/sign_event_local_dynamic"
MIPS_BINARY="$CURRENT_DIR/sign_event_mips"
MIPS_BINARY_DYNAMIC="$CURRENT_DIR/sign_event_mips_dynamic"
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

# Ensure correct permissions for secp256k1_mips_architecture
sudo chown -R $USER:$USER $PARENT_DIR/secp256k1_mips_architecture
chmod -R u+rwx $PARENT_DIR/secp256k1_mips_architecture

# Function to clean up build directories
function clean_build_directories() {
    echo "Cleaning up build directories..."
    cd $PARENT_DIR/secp256k1_mips_architecture
    make clean || true
    cd $PARENT_DIR/openssl
    make clean || true
    cd $CURRENT_DIR
}

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

# Function to compile OpenSSL for MIPS architecture
function compile_openssl_for_mips() {
    echo "Compiling OpenSSL for MIPS architecture..."
    cd $PARENT_DIR/openssl
    ./Configure linux-mips32r2 --prefix=$MIPS_INSTALL_DIR no-shared no-asm \
        CC=$TOOLCHAIN_PREFIX-gcc AR=$TOOLCHAIN_PREFIX-ar \
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

# Function to compile secp256k1 for MIPS architecture
function compile_secp256k1_for_mips() {
    echo "Compiling secp256k1 for MIPS architecture..."
    cd $PARENT_DIR/secp256k1_mips_architecture
    ./autogen.sh
    ./configure --host=mips-linux-gnu --enable-static --disable-shared --enable-module-schnorrsig --enable-module-extrakeys
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

# Function to compile for MIPS architecture with dynamic linking
function compile_for_mips_dynamic() {
    echo "Compiling for MIPS architecture with dynamic linking..."
    $TOOLCHAIN_PREFIX-gcc -O2 $SOURCE_FILE -o $MIPS_BINARY_DYNAMIC \
                          -I$PARENT_DIR/secp256k1_mips_architecture/include \
                          -I$PARENT_DIR/secp256k1_mips_architecture \
                          -I$MIPS_INSTALL_DIR/include \
                          -L$PARENT_DIR/secp256k1_mips_architecture/.libs \
                          -L$MIPS_INSTALL_DIR/lib \
                          -lsecp256k1 -lssl -lcrypto

    if [ $? -eq 0 ]; then
        echo "Dynamic compilation successful: $MIPS_BINARY_DYNAMIC"
    else
        echo "Failed to compile for MIPS architecture with dynamic linking."
        exit 1
    fi
}

# Function to compile for MIPS architecture
function compile_for_mips() {
    echo "Compiling for MIPS architecture..."
    find_lib_paths $MIPS_INSTALL_DIR

    $TOOLCHAIN_PREFIX-gcc -O2 $SOURCE_FILE -o $MIPS_BINARY \
                          -I$PARENT_DIR/secp256k1_mips_architecture/include \
                          -I$MIPS_INSTALL_DIR/include \
                          -L$PARENT_DIR/secp256k1_mips_architecture/.libs \
                          -L$(dirname $LIBSSL_PATH) \
                          $PARENT_DIR/secp256k1_mips_architecture/.libs/libsecp256k1.a $LIBSSL_PATH $LIBCRYPTO_PATH -static

    if [ $? -eq 0 ]; then
        echo "Compilation successful: $MIPS_BINARY"
    else
        echo "Failed to compile for MIPS architecture."
        exit 1
    fi
}

# Function to generate checksums and file sizes, and save them in a JSON file
function generate_checksums() {
    echo "Generating checksums and file sizes..."
    declare -A binaries=(
        ["local_binary"]=$LOCAL_BINARY
        ["local_binary_dynamic"]=$LOCAL_BINARY_DYNAMIC
        ["mips_binary"]=$MIPS_BINARY
        ["mips_binary_dynamic"]=$MIPS_BINARY_DYNAMIC
    )
    
    checksums="{\n"
    for key in "${!binaries[@]}"; do
        binary="${binaries[$key]}"
        if [ -f "$binary" ]; then
            checksum=$(sha256sum $binary | awk '{print $1}')
            size=$(stat --format="%s" $binary)
            checksums+="  \"${key}_checksum\": \"$checksum\",\n"
            checksums+="  \"${key}_size\": \"$size\",\n"
        fi
    done
    checksums="${checksums%,\n}\n}"  # Remove the last comma and add the closing brace
    
    echo -e "$checksums" > $CHECKSUM_FILE
    echo "Checksums and file sizes saved to $CHECKSUM_FILE"
}

# Main execution flow
clone_dependencies
clean_build_directories

# Compile libraries for MIPS architecture
compile_openssl_for_mips
compile_secp256k1_for_mips

# Compile MIPS binaries
compile_for_mips
compile_for_mips_dynamic

# Compile libraries for local architecture
compile_secp256k1_for_local
compile_openssl_for_local

# Compile local binaries
compile_for_local
compile_for_local_dynamic

generate_checksums

echo "All compilations and checksum generation completed successfully."

