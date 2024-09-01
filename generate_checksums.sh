#!/bin/bash

# Define the output JSON file within the binaries directory
BINARY_DIR="./binaries"
CHECKSUM_FILE="${BINARY_DIR}/checksums.json"

# Function to find binaries (files without extensions) and .tar.gz files in the binaries directory
function find_binaries_and_archives() {
    echo "Finding binaries and .tar.gz files in the binaries directory..."
    binaries_and_archives=$(ls -p "$BINARY_DIR" | grep -v / | grep -E '(^[^.]+$|\.tar\.gz$)')
    if [ -z "$binaries_and_archives" ]; then
        echo "No binaries or .tar.gz files found in the binaries directory."
        exit 1
    fi
}

# Function to generate checksums and file sizes, and save them in a JSON file
function generate_checksums() {
    echo "Generating checksums and file sizes..."
    checksums="{"
    for file in $binaries_and_archives; do
        file_path="$BINARY_DIR/$file"
        if [ -f "$file_path" ]; then
            checksum=$(sha256sum "$file_path" | awk '{print $1}')
            size=$(stat --format="%s" "$file_path")
            checksums+="\"${file}_checksum\": \"$checksum\","
            checksums+="\"${file}_size\": \"$size\","
        fi
    done
    # Remove the last comma and add the closing brace
    checksums=$(echo "$checksums" | sed 's/,$//')
    checksums="${checksums}}"

    # Format the JSON using jq
    echo "$checksums" | jq . > $CHECKSUM_FILE
    echo "Checksums and file sizes saved to $CHECKSUM_FILE"
}

# Main execution flow
find_binaries_and_archives
generate_checksums
