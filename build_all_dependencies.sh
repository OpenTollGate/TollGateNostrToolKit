#!/bin/bash

set -e

SCRIPT_DIR="$HOME/TollGateNostrToolKit"
ROUTERS_DIR="$SCRIPT_DIR/routers"
BUILD_SCRIPT="$SCRIPT_DIR/build_custom_dependencies.sh"

# Ensure build_custom_dependencies.sh is executable
if [ ! -x "$BUILD_SCRIPT" ]; then
    echo "Making build_custom_dependencies.sh executable"
    chmod +x "$BUILD_SCRIPT"
fi

# Iterate through each config file and call build_custom_dependencies.sh
for config_file in "$ROUTERS_DIR"/*_config; do
    router_type=$(basename "$config_file" | sed 's/_config$//')
    echo "Building dependencies for router type: $router_type"
    
    "$BUILD_SCRIPT" "$router_type"
    
    if [ $? -ne 0 ]; then
        echo "Build failed for router type: $router_type"
        exit 1
    fi
    
    echo "Build successful for router type: $router_type"
done

echo "All builds completed successfully!"
