#!/bin/bash

# Transfer the binary to the router
ROUTER_IP="192.168.8.1"
REMOTE_PATH="/tmp"
REMOTE_USER="root"
REMOTE_PASS="1"

# Check if the router is reachable
if ping -c 1 $ROUTER_IP &> /dev/null; then
  echo "Router is reachable. Proceeding with file transfer and execution..."

  echo "Transferring $MIPS_BINARY to the router..."
  scp $MIPS_BINARY $REMOTE_USER@$ROUTER_IP:$REMOTE_PATH/

  echo "Running $MIPS_BINARY on the router..."
  sshpass -p $REMOTE_PASS ssh $REMOTE_USER@$ROUTER_IP << EOF
chmod +x $REMOTE_PATH/$(basename $MIPS_BINARY)
$REMOTE_PATH/$(basename $MIPS_BINARY)
EOF

  echo "Done!"
else
  echo "Error: Router is not reachable. Skipping file transfer and execution."
fi

echo "Done!"

