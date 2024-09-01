#!/bin/bash

# Get a list of all files in the current directory
files=$(ls)

# Initialize an array to store unmentioned files
unmentioned_files=()

# Loop through each file
for file in $files; do
    # Skip directories
    if [ -d "$file" ]; then
        continue
    fi
    
    # Check if the file name is mentioned in any other file
    if ! grep -q -r --exclude="$file" --exclude-dir=.git "$file" .; then
        unmentioned_files+=("$file")
    fi
done

# Print the unmentioned files
echo "Files not mentioned in other files:"
for file in "${unmentioned_files[@]}"; do
    echo "$file"
done
