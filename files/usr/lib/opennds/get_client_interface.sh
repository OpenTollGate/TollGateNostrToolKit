#!/bin/sh
#Copyright (C) BlueWave Projects and Services 2015-2023
#This software is released under the GNU GPL license.
#
# Warning - shebang sh is for compatibliity with busybox ash (eg on OpenWrt)
# This is changed to bash automatically by Makefile for generic Linux
#

pid=$(pgrep -f "/bin/sh /usr/lib/opennds/get_client_interface.sh")

# This script requires the iw and ip packages (usually available by default)

if [ -z $(command -v ip) ]; then
	/usr/lib/opennds/libopennds.sh write_to_syslog "ip utility not available - critical error" "err"
	exit 1
fi

if [ -z $(command -v iw) ]; then
	/usr/lib/opennds/libopennds.sh write_to_syslog "unable to detect wireless interface - iw utility not available" "debug"
	iwstatus=false
else
	iwstatus=true
fi

# mac address of client is passed as a command line argument
mac=$1

# exit if mac not passed

if [  $(echo "$mac" | awk -F ':' '{print NF}') -ne 6 ]; then
	echo "
  Usage: get_client_interface.sh [clientmac]

  Returns: [local_interface] [meshnode_mac] [local_mesh_interface]

  Where:
    [local_interface] is the local interface the client is using.

    [meshnode_mac] is the mac address of the 802.11s meshnode the
      client is using (null if mesh not present).

    [local_mesh_interface] is the local 802.11s interface the
      client is using (null if mesh not present).

"
	exit 1
fi

# Get default interface
# This will be the interface NDS is bound to eg. br-lan

clientlocalif=$(ip -4 neigh | awk -F ' ' 'match($s,"'"$mac"' ")>0 {printf $3}')

if [ -z "$clientlocalif" ]; then
	# The client has gone offline eg battery saving or switched to another ssid
	exit 1
fi

clientmeshif=""

if [ "$iwstatus" = true ]; then 
	# Get list of wireless interfaces on this device
	# This list will contain all the wireless interfaces configured on the device
	# eg wlan0, wlan0-1, wlan1, wlan1-1 etc
	interface_list=$(iw dev | awk -F 'Interface ' 'NF>1{printf $2" "}')

	# Scan the wireless interfaces on this device for the client mac
	for interface in $interface_list; do
		macscan=$(iw dev $interface station dump | awk -F " " 'match($s, "'"$mac"'")>0{printf $2}')

		if [ ! -z "$macscan" ]; then
			clientlocalif=$interface
			break
		else
			clientlocalip=$(ip -4 neigh | awk -F ' ' 'match($s,"'"$mac"' ")>0 {printf $1}')
			ping=$(ping -W 1 -c 1 $clientlocalip)
			meshmac=$(iw dev $interface mpp dump | awk -F "$mac " 'NF>1{printf $2}')
			if [ ! -z "$meshmac" ]; then
				clientmeshif=$meshmac
			fi
		fi
	done
fi

# Return the local interface the client is using, the mesh node mac address and the local mesh interface
if [ -z "$clientmeshif" ]; then
	printf "%s" "$clientlocalif"
else
	printf "%s" "$clientlocalif $clientmeshif"
fi

exit 0

