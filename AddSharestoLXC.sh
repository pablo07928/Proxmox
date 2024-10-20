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

if ! grep -q 'media-shares' /etc/pve/lxc/$id.conf; then
    echo '# media-shares' >>/etc/pve/lxc/$id.conf

    { echo 'mp0: /media/amedia/,mp=/media/amedia' ; } | tee -a /etc/pve/lxc/$id.conf
    { echo 'mp0: /media/media/,mp=/edia/amedia' ; } | tee -a /etc/pve/lxc/$id.conf
    { echo 'mp0: /media/nzb/,mp=/media/nzb' ; } | tee -a /etc/pve/lxc/$id.conf
    { echo 'mp0: /media/scripts/,mp=/media/scripts' ; } | tee -a /etc/pve/lxc/$id.conf

    else
    Echo'Shares Already Present"
    
fi


