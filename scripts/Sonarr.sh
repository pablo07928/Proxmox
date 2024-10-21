#!/bin/bash
set -x
clear
# Constant Definitions
container_install_folder="/tmp/Cont_inst"
containers_before_install="$container_install_folder/prevms.txt"
containers_after_install="$container_install_folder/postvms.txt"
base_build_target="https://github.com/tteck/Proxmox/raw/main/ct/sonarr.sh"

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
pct exec $current_lxc_id -- bash -c "systemctl stop sonarr"
sleep 10
pct exec $current_lxc_id -- bash -c "cd /var/lib/sonarr"
pct exec $current_lxc_id -- bash -c "mv /var/lib/sonarr/sonarr.db /var/lib/sonarr/sonarr.db.old"
pct exec $current_lxc_id -- bash -c "mv /var/lib/sonarr/config.xml /var/lib/sonarr/config.xml.old"
pct exec $current_lxc_id -- bash -c "dir -al"
pct exec $current_lxc_id -- bash -c "pwd"
#pct exec $current_lxc_id -- bash -c "mv /media/scripts/sonnar/sonarr.db sonarr.db"
#pct exec $current_lxc_id -- bash -c "mv /media/scripts/sonnar/config.xml config.xml"
pct exec $current_lxc_id -- bash -c "unzip -o /media/scripts/sonarr/backups/sonarr_backup*.zip -d /var/lib/sonarr "
pct exec $current_lxc_id -- bash -c "dir -al"
pct exec $current_lxc_id -- bash -c "sudo chown gonzapa1:users config.xml"
pct exec $current_lxc_id -- bash -c "sudo chown gonzapa1:users sonarr.db"
pct exec $current_lxc_id -- bash -c "systemctl start sonarr"
}

load_functions
prepare_folder
extra_admin_account
extra_admin_password
sleep 5
base_build
find_container_id
create_second_admin
add_standard_shares
reboot_container
iptables_install
configure_application
reboot_container









