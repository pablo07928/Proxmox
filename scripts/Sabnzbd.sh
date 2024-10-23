#!/bin/bash
clear
# Constant Definitions
container_install_folder="/tmp/Cont_inst"
containers_before_install="$container_install_folder/prevms.txt"
containers_after_install="$container_install_folder/postvms.txt"

load_functions() {
    echo "v12"
    source <(curl -s https://raw.githubusercontent.com/pablo07928/Proxmox/main/functions/build.func)
    source <(curl -s https://raw.githubusercontent.com/pablo07928/Proxmox/main/functions/my.func.sh)
    variables
    color
}


base_build() {
    pct list >$containers_before_install
bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/ct/sabnzbd.sh)"
pct list >$containers_after_install
}


configure_sabnzbd(){
    # Stop sabnzbd service
msg_ok "Stopping sabnzbd service in container $current_lxc_id...pct exec $current_lxc_id systemctl stop sabnzbd"
pct exec $current_lxc_id systemctl stop sabnzbd

sleep 15
# Copy sabnzbd configuration file

msg_ok "renaming sabnzbd.ini to  sabnzbd.ini_orig..."
pct exec $current_lxc_id -- bash -c 'if [ -f /root/.sabnzbd/sabnzbd.ini_orig ]; then rm /root/.sabnzbd/sabnzbd.ini_orig; fi'
#pct exec $current_lxc_id rm /root/.sabnzbd/sabnzbd.ini_orig
pct exec $current_lxc_id mv /root/.sabnzbd/sabnzbd.ini /root/.sabnzbd/sabnzbd.ini_orig

msg_ok "Copying new sabnzbd.ini ..."
pct exec $current_lxc_id -- bash -c 'if [ -f /root/.sabnzbd/sabnzbd.ini_new ]; then rm /root/.sabnzbd/sabnzbd.ini_new; fi'
#pct exec $current_lxc_id rm /root/.sabnzbd/sabnzbd.ini_new
pct exec $current_lxc_id cp /media/scripts/sabnzbd/sabnzbd.ini /root/.sabnzbd/sabnzbd.ini_new
pct exec $current_lxc_id cp /root/.sabnzbd/sabnzbd.ini_new /root/.sabnzbd/sabnzbd.ini
sleep 20
pct exec $current_lxc_id -- bash -c "sed -i 's|ExecStart=python3 SABnzbd.py -s 0.0.0.0:7777|ExecStart=python3 SABnzbd.py -s 0.0.0.0|' /etc/systemd/system/sabnzbd.service"
# Install iptables in the container

# Start sabnzbd service
msg_ok "Starting sabnzbd service in container $current_lxc_id..."
pct exec $current_lxc_id -- bash -c "systemctl daemon-reload"
pct exec $current_lxc_id systemctl start sabnzbd
}

load_functions
prepare_folder
extra_admin_account
extra_admin_password
sleep 20
base_build
find_container_id
create_second_admin
add_standard_shares
reboot_container
iptables_install
configure_sabnzbd
reboot_container









