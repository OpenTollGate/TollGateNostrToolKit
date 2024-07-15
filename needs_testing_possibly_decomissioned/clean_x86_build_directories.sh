#!/bin/bash

# Define directories
PARENT_DIR=".."
CURRENT_DIR=$(pwd)

# Function to clean up build directories
function clean_build_directories() {
    echo "Cleaning up build directories..."
    cd $PARENT_DIR/secp256k1_mips_architecture
    make clean || true
    cd $PARENT_DIR/openssl
    make clean || true
    cd $CURRENT_DIR
}

# Execute function
clean_build_directories
