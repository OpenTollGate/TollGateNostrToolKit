#!/bin/bash

REPO_DIR="$HOME/TollGateNostrToolKit"
BRANCH="dockerize"
WATCH_INTERVAL=60 # Check every 60 seconds

while true; do
  cd $REPO_DIR
  git fetch origin $BRANCH

  LOCAL=$(git rev-parse $BRANCH)
  REMOTE=$(git rev-parse origin/$BRANCH)

  if [ $LOCAL != $REMOTE ]; then
    echo "New changes detected. Pulling changes and restarting the Docker container..."
    git pull origin $BRANCH

    # Get the new commit hash
    NEW_COMMIT_HASH=$(git rev-parse --short HEAD)
    
    # Define the container name with the commit hash
    CONTAINER_NAME="openwrt-builder-$NEW_COMMIT_HASH"
    
    # Check if a container with this name already exists and stop/remove it if so
    if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
      sudo docker stop $CONTAINER_NAME || true
      sudo docker rm $CONTAINER_NAME || true
    fi

    # Build the new Docker image
    sudo docker build -t openwrt-builder .

    # Run the new Docker container with the commit hash in its name
    sudo docker run -d --name $CONTAINER_NAME -v "$(pwd)/binaries:/home/builduser/TollGateNostrToolKit/binaries" openwrt-builder

    # Optionally, you might want to clean up old containers, but be careful with production systems!
    # docker container prune -f

  else
    echo "No new changes. Checking again in $WATCH_INTERVAL seconds..."
  fi

  sleep $WATCH_INTERVAL
done
