#!/bin/bash

# Function to find the new container ID by comparing two files
# Parameters:
#   $1 - File containing the list of VMIDs before installation
#   $2 - File containing the list of VMIDs after installation
find_container_ID() {
    FILE1=$1
    FILE2=$2

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
    echo "$current_lxc_id" > difference

    # Display the new container ID
    echo "The new container ID is: $current_lxc_id"

    # Clean up temporary files
    #rm sorted_file1_vmids.txt sorted_file2_vmids.txt difference
}

# Function to prompt for the second admin account using whiptail
# Returns:
#   The entered admin account
extra_admin_account() {
    extra_admin=$(whiptail --inputbox "Please enter the second admin account:" 8 39 --title "Account Input" --cancel-button Exit-Script 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
        echo "Operation cancelled. Exiting..."
        exit 1
    else
        while [ -z "$extra_admin" ]; do
            whiptail --msgbox "Extra account cannot be blank. Please try again." 8 39 --title "Input Error"
            extra_admin_account
        done
    fi
    echo "$extra_admin"
}





# Function to prompt for the second admin password using whiptail
extra_admin_password() {
    extra_password=$(whiptail --inputbox "Please enter the second admin password:" 8 39 --title "Password Input" --cancel-button Exit-Script 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
        echo "Operation cancelled. Exiting..."
        exit 1
    else
        while [ -z "$extra_password" ]; do
            whiptail --msgbox "Extra account cannot be blank. Please try again." 8 39 --title "Input Error"
            extra_admin_password
        done
    fi
    echo "$extra_password"
}

# Function to create a second admin user in the Proxmox container
create_second_admin() {
    local local_container_id=$1
    local local_extra_admin=$2
    local local_extra_password=$3
    
    # Notify start of admin creation
    msg_info "Creating second admin account"

    # Create the user with a home directory
    pct exec $local_container_id -- bash -c "useradd -m $local_extra_admin"

    # Set the user's password
    pct exec $local_container_id -- bash -c "echo \"$local_extra_admin:$local_extra_password\" | chpasswd"

    # Add the user to the sudo group
    pct exec $local_container_id -- bash -c "usermod -aG sudo $local_extra_admin"

    # Allow the user to execute all commands as root without a password
    pct exec $local_container_id -- bash -c "echo \"$local_extra_admin ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers"

    # Confirmation message
    msg_ok "User $local_extra_admin created, added to sudo group, and granted all root privileges."
}

# Function to prepare the container installation folder
prepare_folder() {
    if [ -d "$container_install_folder" ]; then
        msg_info "Directory $container_install_folder exists. Deleting..."
        rm -rf "$container_install_folder"
        msg_ok "Directory $container_install_folder deleted."
    fi
    mkdir -p "$container_install_folder"
    msg_ok "Directory $container_install_folder recreated."
    # cp /tmp/*.txt "$container_install_folder"
}

# Function to find the new container ID after installation
find_container_id() {
    if [[ ! -f "$containers_before_install" ]]; then
        msg_ok "Error: $containers_before_install does not exist."
        exit 1
    fi
    if [[ ! -f "$containers_after_install" ]]; then
        msg_ok "Error: $containers_after_install does not exist."
        exit 1
    fi

    # Extract the VMID column from both files and sort them
    awk 'NR>1 {print $1}' "$containers_before_install" | sort > sorted_containers_before_install_vmids.txt
    awk 'NR>1 {print $1}' "$containers_after_install" | sort > sorted_containers_after_install_vmids.txt

    # Use comm to find extra VM IDs in the second file
    current_lxc_id=$(comm -13 sorted_containers_before_install_vmids.txt sorted_containers_after_install_vmids.txt)
    comm -13 sorted_containers_before_install_vmids.txt sorted_containers_after_install_vmids.txt > difference
   # Display the new container ID

    msg_ok "The container ID is: $current_lxc_id"
}

find_container_id2() {
    # Check if the input files exist
    if [[ ! -f "$containers_before_install" ]]; then
        msg_ok "Error: $containers_before_install does not exist."
        exit 1
    fi

    if [[ ! -f "$containers_after_install" ]]; then
        msg_ok "Error: $containers_after_install does not exist."
        exit 1
    fi

    # Extract the VMID column from both files and sort them
    awk 'NR>1 {print $1}' "$containers_before_install" | sort > sorted_containers_before_install_vmids.txt
    awk 'NR>1 {print $1}' "$containers_after_install" | sort > sorted_containers_after_install_vmids.txt

    # Return the extra VM IDs in the second file
    comm -13 sorted_containers_before_install_vmids.txt sorted_containers_after_install_vmids.txt

    # Clean up temporary files
    #rm sorted_containers_before_install_vmids.txt sorted_containers_after_install_vmids.txt
}



# Function to add standard shares to the container
add_standard_shares() {
    # Download the script to add shares to the container
    wget -qLO - https://github.com/pablo07928/Proxmox/raw/main/scripts/AddSharestoLXC.sh > $container_install_folder/AddSharestoLXC.sh

    # Make the script executable
    bash -c "chmod +x $container_install_folder/AddSharestoLXC.sh"

    # Notify start of script execution
    msg_ok "Running command $container_install_folder/AddSharestoLXC.sh $current_lxc_id"

    # Execute the script to add shares
    bash -c "$container_install_folder/AddSharestoLXC.sh $current_lxc_id"
}

# Function to reboot the Proxmox container
reboot_container() {
    # Notify start of reboot process
    msg_ok "Rebooting server with ID: $current_lxc_id... pausing for 60 seconds"

    # Reboot the container
    pct exec $current_lxc_id reboot now
}


# Function to reboot a Proxmox container and wait until it's back online
# Parameters:
#   $1 - The ID of the container
#   $2 - The IP address of the container
reboot_container2() {
    local container_id=$1
    local container_ip=$2

    # Initiate the container reboot
    echo "Rebooting container $container_id..."
    pct reboot $container_id
    sleep 10  # Wait for 10 seconds to allow the reboot process to initiate

    # Ping the container until it's back online
    echo "Pinging $container_ip until it's back online..."
    while ! ping -c 1 $container_ip &>/dev/null; do
        sleep 2  # Ping every 2 seconds to check if the container is back online
    done

    # Confirmation message
    echo "Container $container_id has rebooted successfully and is back online!"
}



# Function to get the IP address of a Proxmox container
# Parameters:
#   $1 - The ID of the container
get_container_ip() {
    local container_id=$1

    # Use Proxmox command to get the IP address of the container
    # The command fetches the IP address assigned to eth0 and uses grep to extract it
    ip=$(pct exec $container_id -- ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    
    # Return the IP address
    echo $ip
}


# Function to install and configure iptables within a Proxmox container
# Parameters:
#   $1 - Port number to redirect to (default is 8080)
iptables_install() {
     local local_container=$1
    local port=${2:-8080}

    # Update SABnzbd service configuration
    # Change the service start command to listen on all IPs without specifying the port
    #pct exec $local_container -- bash -c "sed -i 's|ExecStart=python3 SABnzbd.py -s 0.0.0.0:7777|ExecStart=python3 SABnzbd.py -s 0.0.0.0|' /etc/systemd/system/sabnzbd.service"

    # Install iptables in the container
    # This ensures the iptables package is available for setting up firewall rules
    msg_ok "Installing iptables in container $current_lxc_id..."
    pct exec $local_container -- bash -c "apt install iptables -y"

    # Add iptables rule to redirect port 80 to the specified port
    # This sets up a rule to forward traffic from port 80 to the given port
    msg_ok "Adding iptables rule for port redirection in container $current_lxc_id to port $port..."
    pct exec $local_container -- bash -c "iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port $port"

    # Install iptables-persistent in the container
    # This package ensures the iptables rules are saved and loaded on reboot
    msg_ok "Installing iptables-persistent in container $current_lxc_id..."
    pct exec $local_container -- bash -c "apt install iptables-persistent -y"

    # Save the iptables rules
    # Save the current iptables rules to the configuration file for persistence
    pct exec $local_container -- bash -c "iptables-save > /etc/iptables/rules.v4"
}

# Example usage
# Call the function with a specific port or let it default to 8080
# iptables_install 8080  # Or pass any other port as needed






# Function to add standard shares to the container
# Parameters:
#   $1 - The LXC container id
add_standard_shares2() {
    local Container_id=$1

    LXC_CONF="/etc/pve/lxc/$container_id.conf"

    msg_info "Installing Shares"

    # Add a comment for 'media-shares' if not already present
    if ! grep -q 'media-shares' "$LXC_CONF"; then
        echo '# media-shares' | tee -a "$LXC_CONF"
    fi

    # Check each mount point and append if not present
    if ! grep -q 'mp0: /media/amedia' "$LXC_CONF"; then
        echo 'mp0: /media/amedia/,mp=/media/amedia' | tee -a "$LXC_CONF"
    fi
    sleep 1

    if ! grep -q 'mp1: /media/media' "$LXC_CONF"; then
        echo 'mp1: /media/media/,mp=/media/media' | tee -a "$LXC_CONF"
    fi
    sleep 1

    if ! grep -q 'mp2: /media/nzb' "$LXC_CONF"; then
        echo 'mp2: /media/nzb/,mp=/media/nzb' | tee -a "$LXC_CONF"
    fi
    sleep 1

    if ! grep -q 'mp3: /media/scripts' "$LXC_CONF"; then
        echo 'mp3: /media/scripts/,mp=/media/scripts' | tee -a "$LXC_CONF"
    fi

    # Write the current container ID to a script for reference
    echo current_lxc_id=$id >> /etc/pve/lxc/currentid.sh

    msg_ok "Finished adding shares"
}
