#!/bin/bash

# Download and execute the AddSharestoLXC.sh script
bash -c "$(wget -qLO - https://github.com/pablo07928/Proxmox/raw/main/AddSharestoLXC.sh)"

# Load the current LXC ID
echo "Loading source..."
source /etc/pve/lxc/currentid.sh

# Display the current LXC ID
echo "The current LXC ID is: $current_lxc_id"

# Stop sabnzbd service
echo "Stopping sabnzbd service in container $current_lxc_id..."
pct exec $current_lxc_id systemctl stop sabnzbd

# Copy sabnzbd configuration file
echo "Copying sabnzbd.ini to container $current_lxc_id..."
pct exec $current_lxc_id cp /media/scripts/sabnzbd/sabnzbd.ini /root/.sabnzbd/sabnzbd.ini

# Install iptables in the container
echo "Installing iptables in container $current_lxc_id..."
pct exec $current_lxc_id apt install iptables 

# Add iptables rule to redirect port 80 to port 8080
echo "Adding iptables rule for port redirection in container $current_lxc_id..."
pct exec $current_lxc_id iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080

# Start sabnzbd service
echo "Starting sabnzbd service in container $current_lxc_id..."
pct exec $current_lxc_id systemctl start sabnzbd

# Reboot the container
echo "Rebooting container $current_lxc_id..."
pct exec $current_lxc_id reboot now

# Remove the currentid.sh script
echo "Removing /etc/pve/lxc/currentid.sh..."
rm /etc/pve/lxc/currentid.sh
