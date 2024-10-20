#!/bin/bash

# Function to prompt for username
# Function to prompt for username
function prompt_username {
    user=$(whiptail --inputbox "Please enter the username:" 8 39 --title "Username Input" --cancel-button Exit-Script 3>&1 1>&2 2>&3)
        if [ $? -ne 0 ]; then
            echo "Operation cancelled. Exiting..."
            exit 1
        else
            while [ -z "$user" ]; do
            whiptail --msgbox "Username cannot be blank. Please try again." 8 39 --title "Input Error"
            prompt_username
        done
    fi
}

# Function to prompt for PW
function prompt_userpassword {
    password=$(whiptail --inputbox "Please enter the password:" 8 39 --title "Password Input" --cancel-button Exit-Script 3>&1 1>&2 2>&3)
        if [ $? -ne 0 ]; then
            echo "Operation cancelled. Exiting..."
            exit 1
        else
            # Keep prompting until a username is provided
            while [ -z "$password" ]; do
            whiptail --msgbox "password cannot be blank. Please try again." 8 39 --title "Input Error"
            prompt_userpassword
        done
    fi
}
# Function to prompt for NFS
function prompt_nfsserver {
    nfsserver=$(whiptail --inputbox "Please enter the NFS Server    :" 8 39 --title "NFS Input" --cancel-button Exit-Script 3>&1 1>&2 2>&3)
        if [ $? -ne 0 ]; then
            echo "Operation cancelled. Exiting..."
            exit 1
        else
            # Keep prompting until a username is provided
            while [ -z "$nfsserver" ]; do
            whiptail --msgbox "NFS Server cannot be blank. Please try again." 8 39 --title "Input Error"
            prompt_nfsserver
        done
    fi
}



# Initial prompt
prompt_username
# Initial prompt
prompt_userpassword
# Initial prompt
prompt_nfsserver

# Create user with a home directory
useradd -m $user

# Set the user's password
echo "$user:$password" | chpasswd

# Add user to the sudo group
usermod -aG sudo $user

# Allow user to run all commands as root
echo "$user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create share directories
for dir in /media/media /media/amedia /media/nzb /media/scripts; do
    mkdir -p $dir
    chown $user:users $dir
    chmod 777 $dir
done

# Update /etc/fstab with NFS mounts if not already present
if ! grep -q 'media-shares' /etc/fstab; then
    echo '# media-shares' >> /etc/fstab
    echo "$nfsserver:/volume1/Media /media/media  nfs defaults 0 0" >> /etc/fstab
    echo "$nfsserver:/volume1/Amedia /media/amedia  nfs defaults 0 0" >> /etc/fstab
    echo "$nfsserver:/volume1/NZB /media/nzb  nfs defaults 0 0" >> /etc/fstab
    echo "$nfsserver:/volume1/proxmox/1-SCRIPTS /media/scripts  nfs defaults 0 0" >> /etc/fstab
fi

#!/bin/bash

# Function to prompt for username
# Function to prompt for username
function prompt_username {
    user=$(whiptail --inputbox "Please enter the username:" 8 39 --title "Username Input" 3>&1 1>&2 2>&3)
}

# Function to prompt for PW
function prompt_userpassword {
    password=$(whiptail --inputbox "Please enter the password:" 8 39 --title "Password Input" 3>&1 1>&2 2>&3)
}
# Function to prompt for NFS
function prompt_nfsserver {
    nfsserver=$(whiptail --inputbox "Please enter the username:" 8 39 --title "Username Input" 3>&1 1>&2 2>&3)
}



# Initial prompt
prompt_username

# Keep prompting until a username is provided
while [ -z "$user" ]; do
    whiptail --msgbox "Username cannot be blank. Please try again." 8 39 --title "Input Error"
    prompt_username
done


# Initial prompt
prompt_userpassword

# Keep prompting until a username is provided
while [ -z "$password" ]; do
    whiptail --msgbox "password cannot be blank. Please try again." 8 39 --title "Input Error"
    prompt_userpassword
done

# Initial prompt
prompt_nfsserver

# Keep prompting until a username is provided
while [ -z "$nfsserver" ]; do
    whiptail --msgbox "NFS Server cannot be blank. Please try again." 8 39 --title "Input Error"
    prompt_nfsserver
done




# Create user with a home directory
useradd -m $user

# Set the user's password
echo "$user:$password" | chpasswd

# Add user to the sudo group
usermod -aG sudo $user

# Allow user to run all commands as root
echo "$user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create share directories
for dir in /media/media /media/amedia /media/nzb /media/scripts; do
    mkdir -p $dir
    chown $user:users $dir
    chmod 777 $dir
done




# Check if nfs-common is installed
if ! dpkg -l | grep -q nfs-common; then
    echo "nfs-common is not installed. Installing..."
    sudo apt-get update
    sudo apt-get install -y nfs-common
else
    echo "nfs-common is already installed."
fi

# Update /etc/fstab with NFS mounts if not already present
if ! grep -q 'media-shares' /etc/fstab; then
    echo '# media-shares' >> /etc/fstab
    echo "$nfsserver:/volume1/Media /media/media  nfs defaults 0 0" >> /etc/fstab
    echo "$nfsserver:/volume1/Amedia /media/amedia  nfs defaults 0 0" >> /etc/fstab
    echo "$nfsserver:/volume1/NZB /media/nzb  nfs defaults 0 0" >> /etc/fstab
    echo "$nfsserver:/volume1/proxmox/1-SCRIPTS /media/scripts  nfs defaults 0 0" >> /etc/fstab
fi

systemctl daemon-reload

mount -a

echo "User $user created and configured successfully."
