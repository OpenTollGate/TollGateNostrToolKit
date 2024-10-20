#!/bin/bash

# Define repositories and their branches
declare -A REPOS=(
  ["TollBooth"]="main"
  ["TollGateNostrToolKit"]="feature/api_docker"
  ["TollGateFeed"]="main"
)

HOME_DIR="$HOME"
WATCH_INTERVAL=60 # Check every 60 seconds

check_and_update_repo() {
  local repo=$1
  local branch=$2
  
  if [ ! -d "$HOME_DIR/$repo" ]; then
    echo "Repository $repo not found. Cloning..."
    git clone -b $branch "https://github.com/OpenTollGate/$repo.git" "$HOME_DIR/$repo"
    return 0
  fi

  cd "$HOME_DIR/$repo"
  git fetch origin $branch

  LOCAL=$(git rev-parse $branch 2>/dev/null || git rev-parse HEAD)
  REMOTE=$(git rev-parse origin/$branch 2>/dev/null || echo "")

  if [ "$LOCAL" != "$REMOTE" ]; then
    echo "New changes detected in $repo. Pulling changes..."
    git pull origin $branch
    return 0
  fi
  return 1
}

while true; do
  changes_detected=false

  for repo in "${!REPOS[@]}"; do
    if check_and_update_repo "$repo" "${REPOS[$repo]}"; then
      changes_detected=true
    fi
  done

  if $changes_detected; then
    echo "Changes detected. Rebuilding and restarting the Docker container..."

    # Get the new commit hashes
    TOLLBOOTH_HASH=$(cd "$HOME_DIR/TollBooth" && git rev-parse --short HEAD)
    TOOLKIT_HASH=$(cd "$HOME_DIR/TollGateNostrToolKit" && git rev-parse --short HEAD)
    FEED_HASH=$(cd "$HOME_DIR/TollGateFeed" && git rev-parse --short HEAD)
    
    # Define the container name with the commit hashes
    CONTAINER_NAME="opentollgate-${TOLLBOOTH_HASH}-${TOOLKIT_HASH}-${FEED_HASH}"
    
    # Check if a container with this name already exists and stop/remove it if so
    if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
      sudo docker stop $CONTAINER_NAME || true
      sudo docker rm $CONTAINER_NAME || true
    fi

    # Build the new Docker image
    cd "$HOME_DIR/TollGateNostrToolKit"
    sudo docker build -t opentollgate .

    # Run the new Docker container with the commit hashes in its name
    sudo docker run -d --name $CONTAINER_NAME \
      -v "$HOME_DIR/TollBooth:/app/TollBooth" \
      -v "$HOME_DIR/TollGateNostrToolKit:/app/TollGateNostrToolKit" \
      -v "$HOME_DIR/TollGateFeed:/app/TollGateFeed" \
      -v "$HOME_DIR/TollGateNostrToolKit/binaries:/app/binaries" \
      opentollgate

    # Optionally, you might want to clean up old containers, but be careful with production systems!
    # docker container prune -f

  else
    echo "No new changes. Checking again in $WATCH_INTERVAL seconds..."
  fi

  sleep $WATCH_INTERVAL
done
