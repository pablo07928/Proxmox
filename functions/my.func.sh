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

    echo "the new container id is: $current_lxc_id"

    # Clean up temporary files
    rm sorted_file1_vmids.txt sorted_file2_vmids.txt
}

extra_admin_account() { 
 extra_admin=$(whiptail --inputbox "Please enter  second admin account:" 8 39 --title "Account Input" --cancel-button Exit-Script 3>&1 1>&2 2>&3)
        if [ $? -ne 0 ]; then
            echo "Operation cancelled. Exiting..."
            exit 1
        else
            while [ -z "$extra_admin" ]; do
            whiptail --msgbox "Extra account cannot be blank1. Please try again." 8 39 --title "Input Error"
            extra_admin_account
        done
    fi
export $extra_admin

}
extra_admin_password() { 
     extra_password=$(whiptail --inputbox "Please enter  second admin password:" 8 39 --title "password Input" --cancel-button Exit-Script 3>&1 1>&2 2>&3)
        if [ $? -ne 0 ]; then
            echo "Operation cancelled. Exiting..."
            exit 1
        else
            while [ -z "$extra_password" ]; do
            whiptail --msgbox "Extra account cannot be blank1. Please try again." 8 39 --title "Input Error"
            extra_admin_password
        done
    fi
export $extra_password
}



prepare_folder() {
    if [ -d "$container_install_folder" ]; then
        msg_ok "Directory $container_install_folder exists. Deleting..."
        rm -rf "$container_install_folder"
        msg_ok "Directory $container_install_folder deleted."
    fi

    mkdir -p "$container_install_folder"
    #cp /tmp/*.txt "$container_install_folder"
}

find_container_id(){
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
comm -13 sorted_containers_before_install_vmids.txt sorted_containers_after_install_vmids.txt>difference
msg_ok "the new container id is:$current_lxc_id"
}

create_second_admin(){
# Call the function to create  second admin
msg_info "Creating second admin account"
pct exec $current_lxc_id -- bash -c "useradd -m $extra_admin"

# Set the user's password
pct exec $current_lxc_id -- bash -c "echo "$extra_admin:$extra_password" | chpasswd"

# Add user to the sudo group
pct exec $current_lxc_id -- bash -c "usermod -aG sudo $extra_admin"

pct exec $current_lxc_id -- bash -c "echo \"$extra_admin ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers"

msg_ok "User $username created, added to sudo group, and granted all root privileges."
}

add_standard_shares(){
 wget -qLO - https://github.com/pablo07928/Proxmox/raw/main/scripts/AddSharestoLXC.sh > $container_install_folder/AddSharestoLXC.sh
bash -c "chmod +x $container_install_folder/AddSharestoLXC.sh"
msg_ok "Running_command $container_install_folder/AddSharestoLXC.sh $current_lxc_id"
bash -c "$container_install_folder/AddSharestoLXC.sh $current_lxc_id"
 
}
reboot_container(){
msg_ok "Rebooting serverwith id : $current_lxc_id.. pausing for 60 seconds"
pct exec $current_lxc_id reboot now

}

reboot_container2() {
    local container_id=$1
    local container_ip=$2

    echo "Rebooting container $container_id..."
    pct reboot $container_id
    sleep 10

    echo "Pinging $container_ip until it's back online..."
    while ! ping -c 1 $container_ip &>/dev/null; do
        sleep 2
    done

    echo "Container $container_id has rebooted successfully and is back online!"

}

get_container_ip() {
    local container_id=$1
    local ip=$(pct exec $container_id -- ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    echo $ip
}


iptables_install()
{
    
pct exec $current_lxc_id -- bash -c "sed -i 's|ExecStart=python3 SABnzbd.py -s 0.0.0.0:7777|ExecStart=python3 SABnzbd.py -s 0.0.0.0|' /etc/systemd/system/sabnzbd.service"
# Install iptables in the container

msg_ok "Installing iptables in container $current_lxc_id..."
pct exec $current_lxc_id -- bash -c "apt install iptables -y"


# Add iptables rule to redirect port 80 to port 8080
msg_ok "Adding iptables rule for port redirection in container $current_lxc_id..."
pct exec $current_lxc_id -- bash -c "iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080"

# Install iptables-persistant in the container
msg_ok "Installing iptables in container $current_lxc_id..."
pct exec $current_lxc_id -- bash -c "apt install iptables-persistent -y"


pct exec $current_lxc_id -- bash -c "iptables-save > /etc/iptables/rules.v4"
}