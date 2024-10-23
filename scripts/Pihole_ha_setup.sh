#!/bin/bash
#set -x
clear
# Constant Definitions
container_install_folder="/tmp/Cont_inst"
containers_before_install="$container_install_folder/prevms.txt"
containers_after_install="$container_install_folder/postvms.txt"
base_build_target="https://github.com/tteck/Proxmox/raw/main/ct/Pihole1.sh"
base_build_target2="https://github.com/tteck/Proxmox/raw/main/ct/Pihole2.sh"
#application_port="8080"

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

base_build2() {
    pct list >$containers_before_install
bash -c "$(wget -qLO - $base_build_target2)"
pct list >$containers_after_install
}


configure_application(){
    local local_container_id=$1
    local local_extra_admin_user=$2

pct exec $local_container_id -- bash -c "systemctl stop whisparr"
sleep 10
pct exec $local_container_id -- bash -c "mv /var/lib/whisparr/whisparr2.db /var/lib/whisparr/whisparr2.db.old"
pct exec $local_container_id -- bash -c "mv /var/lib/whisparr/config.xml /var/lib/whisparr/config.xml.old"
pct exec $local_container_id -- bash -c "unzip -o /media/scripts/whisparr/backups/whisparr_backup*.zip -d /var/lib/whisparr "
pct exec $local_container_id -- bash -c "sudo chown $local_extra_admin_user:users /var/lib/whisparr/config.xml"
pct exec $local_container_id -- bash -c "sudo chown $local_extra_admin_user:users /var/lib/whisparr/whisparr2.db"
pct exec $local_container_id -- bash -c "systemctl start whisparr"
}




load_functions
prepare_folder
extra_admin_user=$(extra_admin_account)
extra_admin_pw=$(extra_admin_password)
msg_ok "installing PIhole 1"
base_build
container_id=$(find_container_id2)
container_ip=$(get_container_ip $container_id)

msg_ok "installing PIhole 2"
base_build2
container_id2=$(find_container_id2)
container_ip2=$(get_container_ip $container_id)

msg_ok "Container ID = $container_id  Container IP = $container_ip"
msg_ok "Container ID = $container_id2  Container IP = $container_ip2"
msg_ok " create_second_admin on container id:$container_id User Name: $extra_admin_user Password: $extra_admin_pw"

msg_ok "Creating second admin on Pihole1"
create_second_admin $container_id $extra_admin_user $extra_admin_pw
msg_ok "Creating replication account on Pihole1"
create_second_admin $container_id holereplication $extra_admin_pw


msg_ok "Creating second admin on Pihole2"
create_second_admin $container_id2 $extra_admin_user $extra_admin_pw
msg_ok "Creating replication account on Pihole2"
create_second_admin $container_id holereplication $extra_admin_pw


msg_ok "Adding shares to Pihole1"
add_standard_shares2 $container_id
msg_ok "Adding shares to Pihole1"
add_standard_shares2 $container_id2

msg_ok "Reboot Pihole1"
reboot_container2 $container_id $container_ip

msg_ok "Reboot Pihole1"
reboot_container2 $container_id2 $container_ip

pct exec $local_container_id -- bash -c "wget -qLO - https://github.com/pablo07928/Proxmox/raw/main/scripts/AddSharestoLXC.sh > $container_install_folder/AddSharestoLXC.sh"


#iptables_install $container_id $application_port
#configure_application $container_id $extra_admin_user
#reboot_container2 $container_id $container_ip
#msg_ok "The ip for the new server is: $container_ip"
#msg_ok "Server is running on port 80 and on $application_port "





