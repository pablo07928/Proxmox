#!/bin/bash
clear
# Constant Definitions
container_install_folder="/tmp/Cont_inst"
containers_before_install="$container_install_folder/prevms.txt"
containers_after_install="$container_install_folder/postvms.txt"
base_build_target="https://github.com/tteck/Proxmox/raw/main/ct/sabnzbd.sh"
application_port="8080"

load_functions() {
    echo "v12"
    source <(curl -s https://raw.githubusercontent.com/pablo07928/Proxmox/main/functions/build.func)
    source <(curl -s https://raw.githubusercontent.com/pablo07928/Proxmox/main/functions/my.func.sh)
    variables
    color
}


base_build() {
    pct list >$containers_before_install
bash -c "$(wget -qLO - $base_build_target)"
pct list >$containers_after_install
}


configure_application(){
    local local_container_id=$1

    # Stop sabnzbd service
msg_ok "Stopping sabnzbd service in container $local_container_id...pct exec $local_container_id systemctl stop sabnzbd"
pct exec $container_id systemctl stop sabnzbd
sleep 10
# Copy sabnzbd configuration file
msg_ok "renaming sabnzbd.ini to  sabnzbd.ini_orig..."
pct exec $local_container_id -- bash -c 'if [ -f /root/.sabnzbd/sabnzbd.ini_orig ]; then rm /root/.sabnzbd/sabnzbd.ini_orig; fi'
#pct exec $container_id rm /root/.sabnzbd/sabnzbd.ini_orig
pct exec $local_container_id mv /root/.sabnzbd/sabnzbd.ini /root/.sabnzbd/sabnzbd.ini_orig
msg_ok "Copying new sabnzbd.ini ..."
pct exec $local_container_id -- bash -c 'if [ -f /root/.sabnzbd/sabnzbd.ini_new ]; then rm /root/.sabnzbd/sabnzbd.ini_new; fi'
#pct exec $container_id rm /root/.sabnzbd/sabnzbd.ini_new
pct exec $local_container_id cp /media/scripts/sabnzbd/sabnzbd.ini /root/.sabnzbd/sabnzbd.ini_new
pct exec $local_container_id cp /root/.sabnzbd/sabnzbd.ini_new /root/.sabnzbd/sabnzbd.ini
pct exec $local_container_id -- bash -c "sed -i 's|ExecStart=python3 SABnzbd.py -s 0.0.0.0:7777|ExecStart=python3 SABnzbd.py -s 0.0.0.0|' /etc/systemd/system/sabnzbd.service"
# Start sabnzbd service
msg_ok "Starting sabnzbd service in container $local_container_id..."
pct exec $local_container_id -- bash -c "systemctl daemon-reload"
pct exec $local_container_id systemctl start sabnzbd
}




load_functions
prepare_folder
extra_admin_user=$(extra_admin_account)
extra_admin_pw=$(extra_admin_password)
base_build
container_id=$(find_container_id2)
container_ip=$(get_container_ip $container_id)
msg_ok "Container ID = $container_id  Container IP = $container_ip"
msg_ok " create_second_admin on container id:$container_id User Name: $extra_admin_user Password: $extra_admin_pw"
create_second_admin $container_id $extra_admin_user $extra_admin_pw
add_standard_shares2 $container_id
reboot_container2 $container_id $container_ip
iptables_install $container_id $application_port
configure_application $container_id
reboot_container2 $container_id $container_ip
msg_ok "The ip for the new server is: $container_ip"
msg_ok "Server is running on port 80 and on $application_port "






