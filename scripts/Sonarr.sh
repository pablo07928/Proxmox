#!/bin/bash
#set -x
clear
# Constant Definitions
container_install_folder="/tmp/Cont_inst"
containers_before_install="$container_install_folder/prevms.txt"
containers_after_install="$container_install_folder/postvms.txt"
base_build_target="https://github.com/tteck/Proxmox/raw/main/ct/sonarr.sh"
application_port="8989"

load_functions() {
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

pct exec $local_container_id -- bash -c "systemctl stop sonarr"
sleep 10
pct exec $local_container_id -- bash -c "cd /var/lib/sonarr"
pct exec $local_container_id -- bash -c "mv /var/lib/sonarr/sonarr.db /var/lib/sonarr/sonarr.db.old"
pct exec $local_container_id -- bash -c "mv /var/lib/sonarr/config.xml /var/lib/sonarr/config.xml.old"
pct exec $local_container_id -- bash -c "unzip -o /media/scripts/sonarr/backups/sonarr_backup*.zip -d /var/lib/sonarr "
pct exec $local_container_id -- bash -c "sudo chown gonzapa1:users /var/lib/sonarr/config.xml"
pct exec $local_container_id -- bash -c "sudo chown gonzapa1:users /var/lib/sonarr/sonarr.db"
pct exec $local_container_id -- bash -c "systemctl start sonarr"
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





