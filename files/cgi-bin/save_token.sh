#!/bin/sh -e

# Read POST data from stdin
read -r POST_DATA

# Extract variables from POST data
TOKEN=$(echo "$POST_DATA" | grep -oP 'token=\K[^&]*')
MAC=$(echo "$POST_DATA" | grep -oP 'mac=\K[^&]*')

# Decode URL-encoded data
TOKEN=$(echo "$TOKEN" | sed 's/+/ /g; s/%\(..\)/\\x\1/g' | xargs -0 printf '%b')

# Save the token to a temporary file
echo "$TOKEN" > "/tmp/token_${MAC}"

# Trigger the payment script (you might need to adapt the arguments)
./payment.sh auth_client "$MAC" "$TOKEN" "dummy_password"

# Return a response to the client
echo "Content-type: text/html"
echo ""
echo "<html><body>Token saved and processed.</body></html>"
