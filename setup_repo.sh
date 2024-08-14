

if [ -d "$REPO_DIR" ]; then
    cd "$REPO_DIR"
    git pull
else
    git clone "$REPO_URL" "$REPO_DIR"
fi

# Check out the branch
cd "$REPO_DIR"
git checkout -b nostr_client_relay origin/nostr_client_relay
