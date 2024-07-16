#!/bin/bash

# Define the OpenWrt base directory
OPENWRT_DIR="$HOME/openwrt"

# Paths to toolchain and libraries
STAGING_DIR=$(find $OPENWRT_DIR/staging_dir/ -type d -wholename "*/toolchain-mips_24kc_gcc-12.3.0_musl/usr" | head -n 1)
TOOLCHAIN_DIR=$(dirname "$STAGING_DIR")
INCLUDE_DIR=$(find $OPENWRT_DIR/staging_dir/ -type d -wholename "*/target-mips_24kc_musl/root-ath79/usr/include" | head -n 1)
LIB_DIR=$(find $OPENWRT_DIR/build_dir/ -type d -wholename "*/secp256k1-0.1" | head -n 1)/.libs

# Ensure the toolchain is in the PATH
export PATH=$TOOLCHAIN_DIR/bin:$PATH

# Source file and output binary
SOURCE_FILE="$HOME/nostrSigner/sign_event.c"
MIPS_BINARY="$HOME/nostrSigner/sign_event_mips"

# Compile the sign_event program for MIPS architecture
echo "Compiling sign_event.c for MIPS architecture..."
mips-openwrt-linux-gcc -I$INCLUDE_DIR -L$LIB_DIR -o $MIPS_BINARY $SOURCE_FILE -lsecp256k1 -static

if [ $? -eq 0 ]; then
    echo "Compilation successful: $MIPS_BINARY"
else
    echo "Failed to compile sign_event.c for MIPS architecture."
    exit 1
fi



