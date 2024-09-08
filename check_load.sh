#!/bin/bash

sudo apt-get -y install bc

# List of VPS servers
# servers=("helsinki" "falkenstein" "nuremberg")
servers=("falkenstein")
# servers=("falkenstein" "nuremberg")

# Function to check load average
check_load() {
    ssh root@$1.orangesync.tech "uptime | awk '{print \$10}' | cut -d ',' -f1"
}

# Function to check if file exists
check_file() {
    ssh root@$1.orangesync.tech "[ -f /home/username/TollGateNostrToolKit/binaries/openwrt-ath79-nand-glinet_gl-ar300m-nor-squashfs-sysupgrade.bin ] && echo 'exists' || echo 'not exists'"
}

# Main loop
while true; do
    for server in "${servers[@]}"; do
        load=$(check_load $server)
        file_status=$(check_file $server)
        
        echo "Server $server load: $load"  # Print the load
        echo "Server $server file status: $file_status"  # Print file status
        
        if (( $(echo "$load < 0.5" | bc -l) )) || [ "$file_status" == "exists" ]; then
            message="Load average: $load, File status: $file_status"
            notify-send "Alert for server $server" "$message"
            # Optional: play a sound
            paplay /usr/share/sounds/freedesktop/stereo/complete.oga
        fi
    done
    sleep 10  # Check every 10 seconds
done
