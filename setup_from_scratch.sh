# Define variables
USERNAME="username"  # Replace with the desired username
REPO_DIR="/home/$USERNAME/TollGateNostrToolKit"
REPO_URL="https://github.com/chGoodchild/TollGateNostrToolKit.git"


# Execute the curl script as root
curl -sSL https://raw.githubusercontent.com/chGoodchild/vps_general_setup/main/setup.sh | sudo bash

# Check if the user already exists
if id "$USERNAME" &>/dev/null; then
    echo "User $USERNAME already exists."
else
    # Create the non-root user and add to the sudo group
    sudo adduser $USERNAME
    sudo usermod -aG sudo $USERNAME
fi

# Switch to the new user
sudo su - $USERNAME <<EOF
    # Clone the repository or pull the latest changes
    if [ -d "$REPO_DIR" ]; then
        cd "$REPO_DIR"
        git pull
    else
        git clone "$REPO_URL" "$REPO_DIR"
    fi

    # Check out the branch
    cd "$REPO_DIR"
    git checkout -b nostr_client_relay origin/nostr_client_relay

    # Log in to the new user's shell
    exec bash
EOF

# Login as the new user
ssh $USERNAME@localhost
