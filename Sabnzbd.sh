#!/bin/bash

# Download and execute the AddSharestoLXC.sh script
bash -c "$(wget -qLO - https://github.com/pablo07928/Proxmox/raw/main/AddSharestoLXC.sh)"

# Load the current LXC ID
echo "Loading source...v1"
source /etc/pve/lxc/currentid.sh

# Display the current LXC ID
echo "The current LXC ID is: $current_lxc_id"

# Stop sabnzbd service
echo "Stopping sabnzbd service in container $current_lxc_id..."
pct exec $current_lxc_id systemctl stop sabnzbd

sleep 15
# Copy sabnzbd configuration file

echo "renaming sabnzbd.ini to container $current_lxc_id..."
pct exec $current_lxc_id rm /root/.sabnzbd/sabnzbd.ini_orig
pct exec $current_lxc_id mv /root/.sabnzbd/sabnzbd.ini /root/.sabnzbd/sabnzbd.ini_orig

echo "Copying sabnzbd.ini to container $current_lxc_id..."
pct exec $current_lxc_id cp /media/scripts/sabnzbd/sabnzbd.ini /root/.sabnzbd/sabnzbd.ini_new
pct exec $current_lxc_id cp /root/.sabnzbd/sabnzbd.ini_new /root/.sabnzbd/sabnzbd.ini
sleep 20
# Install iptables in the container
echo "Installing iptables in container $current_lxc_id..."
pct exec $current_lxc_id apt install iptables 

# Add iptables rule to redirect port 80 to port 8080
echo "Adding iptables rule for port redirection in container $current_lxc_id..."
pct exec $current_lxc_id iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
sleep 20
# Start sabnzbd service
echo "Starting sabnzbd service in container $current_lxc_id..."
pct exec $current_lxc_id systemctl start sabnzbd


# Remove the currentid.sh script
echo "Removing /etc/pve/lxc/currentid.sh..."
rm /etc/pve/lxc/currentid.sh

# Reboot the container
echo "Rebooting container $current_lxc_id..."
#pct exec $current_lxc_id reboot now
