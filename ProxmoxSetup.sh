#!/bin/bash

# Check if all variables are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <username> <password> <share>"
    echo "Example: $0 newuser password123 nfsserver:/nfs/share"
    exit 1
fi

# Variables
username=$1
password=$2
share=$3

# Create user with a home directory
useradd -m $username

# Set the user's password
echo "$username:$password" | chpasswd

# Add user to the sudo group
usermod -aG sudo $username

# Allow user to run all commands as root
echo "$username ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create share directories
for dir in /media/media /media/amedia /media/nzb /media/scripts; do
    mkdir -p $dir
    chown $username:users $dir
    chmod 777 $dir
done

# Update /etc/fstab with NFS mounts if not already present
if ! grep -q 'media-shares' /etc/fstab; then
    echo '# media-shares' >> /etc/fstab
    echo "$share:/volume1/Media /media/media  nfs defaults 0 0" >> /etc/fstab
    echo "$share:/volume1/Amedia /media/amedia  nfs defaults 0 0" >> /etc/fstab
    echo "$share:/volume1/NZB /media/nzb  nfs defaults 0 0" >> /etc/fstab
    echo "$share:/volume1/proxmox/1-SCRIPTS /media/scripts  nfs defaults 0 0" >> /etc/fstab
fi

echo "User $username created and configured successfully."
