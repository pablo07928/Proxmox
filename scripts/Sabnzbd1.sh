#!/bin/bash
clear
echo "v12"

source <(curl -s https://raw.githubusercontent.com/pablo07928/Proxmox/main/functions/build.func)
source <(curl -s https://raw.githubusercontent.com/pablo07928/Proxmox/main/functions/my.func.sh)
echo "222"
variables
color
catch_errors


temp_root="/tmp/pginstall"


# Check if the directory exists
if [ -d "$temp_root" ]; then
    echo "Directory $temp_root exists. Deleting..."
    rm -rf "$temp_root"
    echo "Directory $temp_root and its contents have been deleted."
else
    echo "Directory $temp_root does not exist."
fi
 
# mkdir $temp_root

# # Defaults
# FILE1="$temp_root/prevms.txt"
# FILE2="$temp_root/postvms.txt"
# msg_ok "$FILE1"
# # -- end defaults --
# sleep 10

# pct list >$FILE1
# bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/ct/sabnzbd.sh)"
# # Download and execute the AddSharestoLXC.sh script
# pct list >$FILE2



# msg_ok "finding container"
# current_lxc_id=(find_container_ID $FILE1 $FILE2)

# msg_ok " Container id is: $current_lxc_id"

# wget -qLO - https://github.com/pablo07928/Proxmox/raw/main/AddSharestoLXC.sh > $temp_root/AddSharestoLXC.sh
# bash -c "chmod +x $temp_root/AddSharestoLXC.sh"
# bash -c "$temp_root/AddSharestoLXC.sh $current_lxc_id"

# echo "Rebooting serverwith id : $current_lxc_id.. pausing for 60 seconds"
# pct exec $current_lxc_id reboot now
# sleep 60
# # Display the current LXC ID


# # Stop sabnzbd service
# echo "Stopping sabnzbd service in container $current_lxc_id...pct exec $current_lxc_id systemctl stop sabnzbd"
# pct exec $current_lxc_id systemctl stop sabnzbd

# sleep 15
# # Copy sabnzbd configuration file

# echo "renaming sabnzbd.ini to container $current_lxc_id..."
# pct exec $current_lxc_id rm /root/.sabnzbd/sabnzbd.ini_orig
# pct exec $current_lxc_id mv /root/.sabnzbd/sabnzbd.ini /root/.sabnzbd/sabnzbd.ini_orig

# echo "Copying sabnzbd.ini to container $current_lxc_id..."
# pct exec $current_lxc_id rm /root/.sabnzbd/sabnzbd.ini_new
# pct exec $current_lxc_id cp /media/scripts/sabnzbd/sabnzbd.ini /root/.sabnzbd/sabnzbd.ini_new
# pct exec $current_lxc_id cp /root/.sabnzbd/sabnzbd.ini_new /root/.sabnzbd/sabnzbd.ini
# sleep 20

# pct exec $current_lxc_id -- bash -c "sed -i 's|ExecStart=python3 SABnzbd.py -s 0.0.0.0:7777|ExecStart=python3 SABnzbd.py -s 0.0.0.0|' /etc/systemd/system/sabnzbd.service"
# # Install iptables in the container
# echo "Installing iptables in container $current_lxc_id..."
# pct exec $current_lxc_id -- bash -c "apt install iptables -y"

# # Add iptables rule to redirect port 80 to port 8080
# echo "Adding iptables rule for port redirection in container $current_lxc_id..."
# pct exec $current_lxc_id -- bash -c "iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080"

# # Start sabnzbd service
# echo "Starting sabnzbd service in container $current_lxc_id..."
# pct exec $current_lxc_id -- bash -c "systemctl daemon-reload"
# pct exec $current_lxc_id systemctl start sabnzbd


# # Reboot the container
# echo "Rebooting container $current_lxc_id..."
# pct exec $current_lxc_id reboot now
