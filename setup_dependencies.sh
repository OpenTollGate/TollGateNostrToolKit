#!/bin/bash

# Check if the script has been run today
LAST_UPDATE_FILE="/tmp/last_update_check"

# Update system if it hasn't been updated today
if [ ! -f "$LAST_UPDATE_FILE" ] || [ "$(date +%Y-%m-%d)" != "$(cat $LAST_UPDATE_FILE)" ]; then
  sudo apt-get update
  echo "$(date +%Y-%m-%d)" > "$LAST_UPDATE_FILE"
else
  echo "System already updated today"
fi

# List of necessary dependencies
declare -a packages=(
  "build-essential" "libncurses5-dev" "libncursesw5-dev" "git" "python3" 
  "rsync" "file" "wget" "clang" "flex" "bison" "g++" "gawk" "gcc-multilib"
  "g++-multilib" "gettext" "libssl-dev" "python3-distutils" "unzip" "zlib1g-dev" "jq"
)

# Install necessary dependencies only if they are not already installed
for pkg in "${packages[@]}"; do
  if ! dpkg -l | grep -qw "$pkg"; then
    sudo apt-get install -y "$pkg"
  else
    echo "$pkg is already installed"
  fi
done

