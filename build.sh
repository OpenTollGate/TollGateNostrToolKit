#!/bin/bash

# Function to check if the script is run as root
if [ "$EUID" -eq 0 ]; then
  echo "Please do not run this script as root"
  exit 1
fi

# Check if the script has been run today
LAST_UPDATE_FILE="/tmp/last_update_check"

# Update system if it hasn't been updated today
if [ ! -f "$LAST_UPDATE_FILE" ] || [ "$(date +%Y-%m-%d)" != "$(cat $LAST_UPDATE_FILE)" ]; then
  sudo apt-get update
  echo "$(date +%Y-%m-%d)" > "$LAST_UPDATE_FILE"
else
  echo "System already updated today"
fi

# Install necessary dependencies only if they are not already installed
declare -a packages=("build-essential" "libncurses5-dev" "libncursesw5-dev" "git" "python3" "rsync" "file" "wget")

for pkg in "${packages[@]}"; do
  if ! dpkg -l | grep -qw "$pkg"; then
    sudo apt-get install -y "$pkg"
  else
    echo "$pkg is already installed"
  fi
done

# Variables
OPENWRT_DIR=../openwrt
CONFIG_FILE=".config"
FEEDS_FILE="feeds.conf"
SOURCE_FILE="$PWD/sign_event.c"
MIPS_BINARY="$PWD/sign_event_mips"
LIB_DIR="$PWD/lib"
CUSTOM_FEED_NAME="custom"
CUSTOM_FEED_URL="https://github.com/chGoodchild/secp256k1_openwrt_feed.git"

# Predefined configuration
CONFIG_CONTENT="CONFIG_TARGET_ath79=y
CONFIG_TARGET_ath79_generic=y
CONFIG_TARGET_ath79_generic_DEVICE_glinet_gl-ar300m=y
CONFIG_PACKAGE_busybox=y
CONFIG_PACKAGE_dnsmasq=y
CONFIG_PACKAGE_dropbear=y
CONFIG_PACKAGE_libc=y
CONFIG_PACKAGE_libgcc=y
CONFIG_PACKAGE_libopenssl=y
CONFIG_PACKAGE_libsecp256k1=y"

# Navigate to the existing OpenWrt build directory
cd $OPENWRT_DIR

# Set up the environment and compile the toolchain if not already done
if [ ! -d "$OPENWRT_DIR/staging_dir" ]; then
    echo "Setting up the environment..."
    echo "$CONFIG_CONTENT" > $CONFIG_FILE
    make defconfig
    make toolchain/install
else
    echo "Toolchain already set up."
fi

# Ensure custom feeds are set
echo "Setting up custom feeds..."
cat << EOF > $FEEDS_FILE
src-git base https://git.openwrt.org/openwrt/openwrt.git;v22.03.4
src-git-full packages https://git.openwrt.org/feed/packages.git^38cb0129739bc71e0bb5a25ef1f6db70b7add04b
src-git-full luci https://git.openwrt.org/project/luci.git^ce20b4a6e0c86313c0c6e9c89eedf8f033f5e637
src-git-full routing https://git.openwrt.org/feed/routing.git^1cc7676b9f32acc30ec47f15fcb70380d5d6ef01
src-git-full telephony https://git.openwrt.org/feed/telephony.git^5087c7ecbc4f4e3227bd16c6f4d1efb0d3edf460
src-git $CUSTOM_FEED_NAME $CUSTOM_FEED_URL
EOF

# Update and install feeds
echo "Updating and installing feeds..."
./scripts/feeds update -a

if [ $? -ne 0 ]; then
    echo "Feeds update failed"
    exit 1
fi

./scripts/feeds install -a

if [ $? -ne 0 ]; then
    echo "Feeds install failed"
    exit 1
fi

# Set up the environment for building
echo "Setting up the environment..."
echo "$CONFIG_CONTENT" | tee $CONFIG_FILE > /dev/null
make defconfig

if [ $? -ne 0 ]; then
    echo "Failed to make defconfig."
    exit 1
fi

# Build the toolchain
echo "Installing toolchain..."
make clean
make -j$(nproc) V=s toolchain/install

if [ $? -ne 0 ]; then
    echo "Toolchain install failed."
    exit 1
fi

# Build the secp256k1 package
echo "Building secp256k1 package..."
make -j$(nproc) V=s package/secp256k1/compile

if [ $? -ne 0 ]; then
    echo "Toolchain or secp256k1 package installation failed."
    exit 1
fi

# Compile the sign_event program for MIPS architecture
echo "Compiling sign_event.c for MIPS architecture..."
STAGING_DIR=$(pwd)/staging_dir
TOOLCHAIN_DIR=$STAGING_DIR/toolchain-mips_24kc_gcc-11.2.0_musl
export PATH=$TOOLCHAIN_DIR/bin:$PATH
export STAGING_DIR

# Make sure secp256k1 headers and libraries are available
SECP256K1_DIR="$LIB_DIR/secp256k1"
INCLUDE_DIR="$SECP256K1_DIR/include"
LIBS="-L$SECP256K1_DIR/.libs -lsecp256k1 -lgmp"

mips-openwrt-linux-gcc -I$INCLUDE_DIR -o $MIPS_BINARY $SOURCE_FILE $LIBS -static

if [ $? -eq 0 ]; then
    echo "Compilation successful: $MIPS_BINARY"
else
    echo "Failed to compile sign_event.c for MIPS architecture."
    exit 1
fi

# Transfer the binary to the router
ROUTER_IP="192.168.8.1"
REMOTE_PATH="/tmp"
REMOTE_USER="root"
REMOTE_PASS="1"
echo "Transferring $MIPS_BINARY to the router..."
scp $MIPS_BINARY $REMOTE_USER@$ROUTER_IP:$REMOTE_PATH/

# Run the binary on the router
echo "Running $MIPS_BINARY on the router..."
sshpass -p $REMOTE_PASS ssh $REMOTE_USER@$ROUTER_IP << EOF
chmod +x $REMOTE_PATH/$(basename $MIPS_BINARY)
$REMOTE_PATH/$(basename $MIPS_BINARY)
EOF

echo "Done!"

