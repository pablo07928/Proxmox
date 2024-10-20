#!/bin/bash
function prompt_lxc_ID {
    id=$(whiptail --inputbox "Please enter the LXC ID:" 8 39 --title "LXC Input" --cancel-button Exit-Script 3>&1 1>&2 2>&3)
        if [ $? -ne 0 ]; then
            echo "Operation cancelled. Exiting..."
            exit 1
        else
            while [ -z "$id" ]; do
            whiptail --msgbox "LXC cannot be blank. Please try again." 8 39 --title "Input Error"
            prompt_lxc_ID
        done
    fi
}
prompt_lxc_ID
{ echo 'mp0: /media/amedia/,mp=/media/amedia' ; } | tee -a /etc/pve/lxc/$id.conf
