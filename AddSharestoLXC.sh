#!/bin/bash
function prompt_lxc_ID {
    id=$(whiptail --inputbox "Please enter the LXC ID:" 8 39 --title "LXC Input" --cancel-button Exit-Script 3>&1 1>&2 2>&3)
        if [ $? -ne 0 ]; then
            echo "Operation cancelled. Exiting..."
            exit 1
        else
            while [ -z "$id" ]; do
            whiptail --msgbox "LXC cannot be blank1. Please try again." 8 39 --title "Input Error"
            prompt_lxc_ID
        done
    fi
}
prompt_lxc_ID
LXC_CONF="/etc/pve/lxc/$id.conf"
# Add a comment for 'media-shares' if not already present
if ! grep -q 'media-shares' "$LXC_CONF"; then
    echo '#media-shares' | tee -a "$LXC_CONF"
fi

# Check each mount point and append if not present
if ! grep -q 'mp0: /media/amedia' "$LXC_CONF"; then
    echo 'mp0: /media/amedia/,mp=/media/amedia' | tee -a "$LXC_CONF"
fi

if ! grep -q 'mp1: /media/media' "$LXC_CONF"; then
    echo 'mp1: /media/media/,mp=/media/media' | tee -a "$LXC_CONF"
fi

if ! grep -q 'mp2: /media/nzb' "$LXC_CONF"; then
    echo 'mp2: /media/nzb/,mp=/media/nzb' | tee -a "$LXC_CONF"
fi

if ! grep -q 'mp3: /media/scripts' "$LXC_CONF"; then
    echo 'mp3: /media/scripts/,mp=/media/scripts' | tee -a "$LXC_CONF"
fi

echo current_lxc_id=$id>>/etc/pve/lxc/currentid.sh

echo "finished adding shares"
