#!/bin/sh

# Log all environment variables to /tmp/openvpn.env.log for debugging
env > /tmp/openvpn.env.log

# Extract the username from the environment variables (as set by OpenVPN)
USERNAME="$username"

# Log the extracted username for debugging
echo "Extracted USERNAME: $USERNAME" >> /tmp/openvpn.env.log

# Check if the username starts with "lnurl" or "cashu" (case-insensitive)
if echo "$USERNAME" | grep -qiE "^(lnurl|cashu)"; then
    echo "Username starts with lnurl or cashu, authentication success."
    echo "Username starts with lnurl or cashu, authentication success." >> /tmp/openvpn.env.log
    exit 0  # Authentication success

# Else, check if the username is a valid pow proof with difficulty of 2 using /etc/openvpn/pow.sh
elif /etc/openvpn/pow.sh verify "$USERNAME" 2; then
    echo "Username is a valid pow proof, authentication success."
    echo "Username is a valid pow proof, authentication success." >> /tmp/openvpn.env.log
    exit 0  # Authentication success

else
    echo "Authentication failed."
    echo "Authentication failed." >> /tmp/openvpn.env.log
    exit 1  # Authentication failure
fi
