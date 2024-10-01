#!/bin/sh


# Get the absolute path to the script directory
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
JSON_PATH="/nostr/shell"
mkdir -p $JSON_PATH
OUTPUT_FILE="$JSON_PATH/nostr_keys.json"


# Function to check if specific keys exist and are valid
check_nostr_keys() {
    keys_exist=true
    for key in npub_hex nsec_hex; do
        value=$(jq -r --arg key "$key" '.[$key]' "$OUTPUT_FILE")
        if [ -z "$value" ] || [ "$value" = "null" ]; then
            echo "Error: Missing or empty value for $key in $OUTPUT_FILE"
            keys_exist=false
            break
        fi
    done

    if $keys_exist; then
        return 0  # Returning 0, indicating success
    else
        echo "Required keys are not present or are empty, need to generate new keys."
        return 1
    fi
}

# First check if nostr_keys.json exists and contains the necessary keys
if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
    if check_nostr_keys; then
	echo "Nostr keys already exist in $OUTPUT_FILE"
        exit 0
    fi
else
    echo "$OUTPUT_FILE does not exist or is empty."
    "generate_npub" | jq > "$OUTPUT_FILE"

    # Check again if the necessary keys now exist
    if check_nostr_keys; then
	echo "Nostr keys generated and saved to $OUTPUT_FILE"
    else
	echo "Failed to generate Nostr keys."
	exit 1
    fi
fi


