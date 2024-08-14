#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Define variables
BUILD_ROOT=~/openwrt/build_dir/target-mips_24kc_musl
PKG_NAME=gltollgate
PKG_VERSION=1.0
PKG_BUILD_DIR="${BUILD_ROOT}/${PKG_NAME}-${PKG_VERSION}"
REPO_URL="https://github.com/chGoodchild/GLTollGate.git"
BRANCH="42-generate-nsec-on-the-router"

# Function to display messages
function info() {
    echo -e "\e[32m[INFO]\e[0m $1"
}

function error() {
    echo -e "\e[31m[ERROR]\e[0m $1"
    exit 1
}

# Remove existing build directory if it exists
if [ -d "${PKG_BUILD_DIR}" ]; then
    info "Removing existing build directory at ${PKG_BUILD_DIR}..."
    rm -rf "${PKG_BUILD_DIR}"
fi

# Create the build directory
info "Creating build directory at ${PKG_BUILD_DIR}..."
mkdir -p "${PKG_BUILD_DIR}"

# Clone the repository
info "Cloning repository from ${REPO_URL} (branch: ${BRANCH})..."
git clone "${REPO_URL}" "${PKG_BUILD_DIR}" --branch "${BRANCH}" --single-branch

# Navigate to the build directory
cd "${PKG_BUILD_DIR}" || error "Failed to navigate to ${PKG_BUILD_DIR}."

# Update submodules if any
if [ -f ".gitmodules" ]; then
    info "Updating submodules..."
    git submodule update --init --recursive
else
    info "No submodules to update."
fi

# Verify the existence of nostr/c directory
NOSTR_C_DIR="${PKG_BUILD_DIR}/nostr/c"
if [ -d "${NOSTR_C_DIR}" ]; then
    info "Found nostr/c directory. Copying its contents to the build root..."
    cp -fpR "${NOSTR_C_DIR}/"* "${PKG_BUILD_DIR}/"
else
    error "The expected subdirectory 'nostr/c' does not exist in the repository."
fi

info "Listing contents of the build directory after copying:"
ls -la "${PKG_BUILD_DIR}"

info "Preparation of GLTollGate is complete."

