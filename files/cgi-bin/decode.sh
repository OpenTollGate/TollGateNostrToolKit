#!/bin/sh

decode_token() {
    echo "Decoding token..."
    
    # Remove the 'cashuA' prefix before decoding
    BASE64_TOKEN=$(echo "${TOKEN:6}")
    echo "Base64 Token: $BASE64_TOKEN"

    # Clean up the base64 token to remove any invalid characters
    CLEANED_BASE64_TOKEN=$(echo "$BASE64_TOKEN" | tr -d '\n\r')
    echo "Cleaned Base64 Token: $CLEANED_BASE64_TOKEN"

    # Ensure proper padding
    PADDING=$((${#CLEANED_BASE64_TOKEN} % 4))
    if [ $PADDING -ne 0 ]; then
        CLEANED_BASE64_TOKEN="${CLEANED_BASE64_TOKEN}$(printf '%0.s=' $(seq 1 $((4 - PADDING))))"
    fi
    echo "Padded Base64 Token: $CLEANED_BASE64_TOKEN"

    # Decode base64, handle any errors
    DECODED_TOKEN=$(echo "$CLEANED_BASE64_TOKEN" | base64 --decode 2>/dev/null)
    if [ -z "$DECODED_TOKEN" ]; then
        echo "Error decoding token or token is empty."
        exit 1
    fi

    # Validate JSON format
    if ! echo "$DECODED_TOKEN" | jq . > /dev/null 2>&1; then
        echo "Decoded token is not valid JSON."
        exit 1
    fi

    # Print the decoded JSON
    echo "Decoded JSON: $DECODED_TOKEN"
}

# Example usage
TOKEN="cashuAeyJ0b2tlbiI6W3sibWludCI6Imh0dHBzOi8vbWludC5taW5pYml0cy5jYXNoL0JpdGNvaW4iLCJwcm9vZnMiOlt7ImlkIjoiOW1sZmQ1dkN6Z0dsIiwiYW1vdW50IjoxLCJzZWNyZXQiOiI0NDA3OGY2M2RmNzdjNmY1YjZhYmUzZWM0OTE4YjY2ZTYwZTAzNTY4MDFkZjMyZTUzODliMWRjODc2M2M5MDRiIiwiQyI6IjAyOTgxZDljZjE2NDIxMWYwOTA5NDFjZjQ1NmFkZGNiNTIyYWExYmM3NzQ0NDI0YjlhNmUyNGE5Yjk2NjA1NzNmZCJ9LHsiaWQiOiI5bWxmZDV2Q3pnR2wiLCJhbW91bnQiOjQsInNlY3JldCI6IjA2ZTg3MmYxMWMxN2Y5MTgzODY4YWJiM2EyN2QxNjNiYmViZDNjZGUxMzU4OThhZjFhZmMzOTkwNWE3ZmJkMDkiLCJDIjoiMDNmMTU0MTljMTViOGFhYmE2Mzc4Yzc2NGQ4MDNhMDQ1NjA3ZWU2YmVhMDNiYjliNzIyNzljOWNmZTM5MDUxM2I5In1dfV0sInVuaXQiOiJzYXQiLCJtZW1vIjoiU2VudCBmcm9tIE1pbmliaXRzIn0"
decode_token
