#!/bin/bash

# Ensure the script exits on any error
set -e

# Define directories and paths
OPENWRT_DIR="$HOME/openwrt"
SCRIPT_DIR="$HOME/nostrSigner"
PROGRAM_NAME="RelayLink"
C_FILE="$SCRIPT_DIR/${PROGRAM_NAME}.c"
OBJ_FILE="$SCRIPT_DIR/${PROGRAM_NAME}.o"
MIPS_BINARY="$SCRIPT_DIR/${PROGRAM_NAME}_mips"

# Find and set STAGING_DIR
export STAGING_DIR=$(find $OPENWRT_DIR/staging_dir/ -type d -wholename "*/toolchain-mips_24kc_gcc-12.3.0_musl" | head -n 1)
TOOLCHAIN_DIR=$(dirname "$STAGING_DIR/usr")

# Ensure the toolchain binaries are in the PATH
export PATH=$TOOLCHAIN_DIR/bin:$PATH

# Define include and library directories
INCLUDE_DIR="$OPENWRT_DIR/staging_dir/target-mips_24kc_musl/usr/include"
LIB_DIRS=(
    "$OPENWRT_DIR/staging_dir/target-mips_24kc_musl/usr/lib"
)

# Set LD_LIBRARY_PATH to include necessary library directories
export LD_LIBRARY_PATH=${LIB_DIRS[0]}:$LD_LIBRARY_PATH

# Compile the source file to an object file with verbose output
echo "Compiling ${PROGRAM_NAME}.c to object file..."
mips-openwrt-linux-gcc -v -I$INCLUDE_DIR -c $C_FILE -o $OBJ_FILE

# Link the object file to create the final binary with verbose output and full paths to static libraries
echo "Linking object file to create binary..."
mips-openwrt-linux-gcc -v -o $MIPS_BINARY $OBJ_FILE \
  $OPENWRT_DIR/staging_dir/target-mips_24kc_musl/usr/lib/libwebsockets.a \
  $OPENWRT_DIR/staging_dir/target-mips_24kc_musl/usr/lib/libssl.a \
  $OPENWRT_DIR/staging_dir/target-mips_24kc_musl/usr/lib/libcrypto.a \
  $OPENWRT_DIR/staging_dir/target-mips_24kc_musl/usr/lib/libcap.a \
  $OPENWRT_DIR/staging_dir/toolchain-mips_24kc_gcc-12.3.0_musl/lib/libatomic.a \
  -static

if [ $? -eq 0 ]; then
    echo "Compilation successful: $MIPS_BINARY"
else
    echo "Failed to compile ${PROGRAM_NAME}.c for MIPS architecture."
    exit 1
fi

