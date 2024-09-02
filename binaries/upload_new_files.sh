#!/bin/bash

# Set the release tag
RELEASE_TAG="v0.0.8"

# Get the list of already uploaded files
UPLOADED_FILES=$(gh release view $RELEASE_TAG --json assets -q '.assets[].name')

# Loop through all files in the current directory
for file in *; do
    # Check if the file is already uploaded
    if ! echo "$UPLOADED_FILES" | grep -q "^$file$"; then
        echo "Uploading $file..."
        gh release upload $RELEASE_TAG "$file"
    else
        echo "Skipping $file (already uploaded)"
    fi
done
