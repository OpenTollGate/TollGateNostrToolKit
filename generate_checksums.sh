#!/bin/bash

# Define the output JSON file within the binaries directory
BINARY_DIR="./binaries"
CHECKSUM_FILE="${BINARY_DIR}/checksums.json"

# Function to find all files in the binaries directory except checksums.json
function find_files() {
    echo "Finding files in the binaries directory..."
    files=$(find "$BINARY_DIR" -type f -not -name "checksums.json")
    if [ -z "$files" ]; then
        echo "No files found in the binaries directory."
        exit 1
    fi
}

# Function to generate checksums and file sizes, and save them in a JSON file
function generate_checksums() {
    echo "Generating checksums and file sizes..."
    checksums="{"
    while IFS= read -r file_path; do
        file=$(basename "$file_path")
        checksum=$(sha256sum "$file_path" | awk '{print $1}')
        size=$(stat --format="%s" "$file_path")
        checksums+="\"${file}_checksum\": \"$checksum\","
        checksums+="\"${file}_size\": \"$size\","
    done <<< "$files"
    # Remove the last comma and add the closing brace
    checksums=$(echo "$checksums" | sed 's/,$//')
    checksums="${checksums}}"

    # Format the JSON using jq
    echo "$checksums" | jq . > $CHECKSUM_FILE
    echo "Checksums and file sizes saved to $CHECKSUM_FILE"
}

# Main execution flow
find_files
generate_checksums
