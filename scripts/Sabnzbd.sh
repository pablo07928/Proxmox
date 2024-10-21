#!/bin/bash
echo "v10"
FILE1="/tmp/prevms.txt"
FILE2="/tmp/postvms.txt"

pct list >/tmp/prevms.txt

bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/ct/sabnzbd.sh)"
# Download and execute the AddSharestoLXC.sh script

pct list >/tmp/postvms.txt

# Define the input files
# Check if the input files exist
if [[ ! -f "$FILE1" ]]; then
    echo "Error: $FILE1 does not exist."
    exit 1
fi

if [[ ! -f "$FILE2" ]]; then
    echo "Error: $FILE2 does not exist."
    exit 1
fi

# Extract the VMID column from both files and sort them
awk 'NR>1 {print $1}' "$FILE1" | sort > sorted_file1_vmids.txt
awk 'NR>1 {print $1}' "$FILE2" | sort > sorted_file2_vmids.txt

# Use comm to find extra VM IDs in the second file
current_lxc_id=$(comm -13 sorted_file1_vmids.txt sorted_file2_vmids.txt)
comm -13 sorted_file1_vmids.txt sorted_file2_vmids.txt>difference
echo "the new container id is:$current_lxc_id"

#source /tmp/currentid.sh

# Clean up temporary files
#rm sorted_file1_vmids.txt sorted_file2_vmids.txt


wget -qLO - https://github.com/pablo07928/Proxmox/raw/main/AddSharestoLXC.sh>/tmp/AddSharestoLXC.sh
bash -c "chmod +x /tmp/AddSharestoLXC.sh"
bash -c "/tmp/AddSharestoLXC.sh $current_lxc_id"

echo "Rebooting serverwith id : $current_lxc_id.. pausing for 60 seconds"
pct exec $current_lxc_id reboot now
sleep 60
# Display the current LXC ID


# Stop sabnzbd service
echo "Stopping sabnzbd service in container $current_lxc_id...pct exec $current_lxc_id systemctl stop sabnzbd"
pct exec $current_lxc_id systemctl stop sabnzbd

sleep 15
# Copy sabnzbd configuration file

echo "renaming sabnzbd.ini to container $current_lxc_id..."
pct exec $current_lxc_id rm /root/.sabnzbd/sabnzbd.ini_orig
pct exec $current_lxc_id mv /root/.sabnzbd/sabnzbd.ini /root/.sabnzbd/sabnzbd.ini_orig

echo "Copying sabnzbd.ini to container $current_lxc_id..."
pct exec $current_lxc_id rm /root/.sabnzbd/sabnzbd.ini_new
pct exec $current_lxc_id cp /media/scripts/sabnzbd/sabnzbd.ini /root/.sabnzbd/sabnzbd.ini_new
pct exec $current_lxc_id cp /root/.sabnzbd/sabnzbd.ini_new /root/.sabnzbd/sabnzbd.ini
sleep 20

pct exec $current_lxc_id -- bash -c "sed -i 's|ExecStart=python3 SABnzbd.py -s 0.0.0.0:7777|ExecStart=python3 SABnzbd.py -s 0.0.0.0|' /etc/systemd/system/sabnzbd.service"
# Install iptables in the container
echo "Installing iptables in container $current_lxc_id..."
pct exec $current_lxc_id -- bash -c "apt install iptables -y"

# Add iptables rule to redirect port 80 to port 8080
echo "Adding iptables rule for port redirection in container $current_lxc_id..."
pct exec $current_lxc_id -- bash -c "iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080"

# Start sabnzbd service
echo "Starting sabnzbd service in container $current_lxc_id..."
pct exec $current_lxc_id -- bash -c "systemctl daemon-reload"
pct exec $current_lxc_id systemctl start sabnzbd


# Reboot the container
echo "Rebooting container $current_lxc_id..."
pct exec $current_lxc_id reboot now