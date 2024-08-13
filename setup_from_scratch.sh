REPO_DIR="$HOME/TollGateNostrToolKit"
REPO_URL="https://github.com/chGoodchild/TollGateNostrToolKit.git"


curl -sSL https://raw.githubusercontent.com/chGoodchild/vps_general_setup/main/setup.sh | bash

if [ -d "$REPO_DIR" ]; then
    # If the directory exists, navigate into it and pull the latest changes
    cd "$REPO_DIR"
    git pull
else
    # If the directory does not exist, clone the repository
    git clone "$REPO_URL"
fi


git checkout -b nostr_client_relay origin/nostr_client_relay

