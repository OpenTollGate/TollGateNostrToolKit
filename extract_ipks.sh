#!/bin/bash

# Directory containing the tar files
SOURCE_DIR="~/TollGateNostrToolKit/binaries"

# Directory where files will be extracted
EXTRACT_DIR="/tmp/extracted_ipks"

# Create extraction directory if it doesn't exist
mkdir -p "$EXTRACT_DIR"

# List of IPK files to extract
IPK_FILES=(
    "mips_24kc/custom/relaylink_1.0-1_mips_24kc.ipk"
    "mips_24kc/custom/signevent_1.0-1_mips_24kc.ipk"
    "mips_24kc/custom/libwallycore_0.8.1-1_mips_24kc.ipk"
    "mips_24kc/custom/libsecp256k1_0.1-1_mips_24kc.ipk"
    "mips_24kc/custom/gltollgate_1.0-1_mips_24kc.ipk"
)

# Function to extract device type from filename
get_device_type() {
    local filename="$1"
    case "$filename" in
        *ath79_archer_c7_v2*) echo "ath79_archer_c7_v2" ;;
        *ath79_archer_c7_v5*) echo "ath79_archer_c7_v5" ;;
        *ath79_glar300m*) echo "ath79_glar300m" ;;
        *) echo "unknown" ;;
    esac
}

# Loop through each tar file
for tar_file in "$SOURCE_DIR"/*.tar.gz; do
    # Get the device type
    device_type=$(get_device_type "$(basename "$tar_file")")
    
    # Extract specified IPK files
    for ipk_file in "${IPK_FILES[@]}"; do
        # Extract the filename from the path
        filename=$(basename "$ipk_file")
        
        # Create the new filename with device type
        new_filename="${filename%.*}_${device_type}.ipk"
        
        # Extract the file
        tar -xzvf "$tar_file" "$ipk_file" -O > "$EXTRACT_DIR/$new_filename"
        
        if [ $? -eq 0 ]; then
            echo "Extracted $new_filename from $(basename "$tar_file")"
        else
            echo "Failed to extract $ipk_file from $(basename "$tar_file")"
        fi
    done
done

echo "Extraction complete. Files are in $EXTRACT_DIR"
