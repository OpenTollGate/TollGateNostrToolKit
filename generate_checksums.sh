#!/bin/bash

# Define the output JSON file
CHECKSUM_FILE="checksums.json"

# Function to find binaries (files without extensions) and .tar.gz files in the current directory
function find_binaries_and_archives() {
    echo "Finding binaries and .tar.gz files in the current directory..."
    binaries_and_archives=$(ls -p | grep -v / | grep -E '(^[^.]+$|\.tar\.gz$)')
    if [ -z "$binaries_and_archives" ]; then
        echo "No binaries or .tar.gz files found in the current directory."
        exit 1
    fi
}

# Function to generate checksums and file sizes, and save them in a JSON file
function generate_checksums() {
    echo "Generating checksums and file sizes..."
    checksums="{"
    for file in $binaries_and_archives; do
        if [ -f "$file" ]; then
            checksum=$(sha256sum "$file" | awk '{print $1}')
            size=$(stat --format="%s" "$file")
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
