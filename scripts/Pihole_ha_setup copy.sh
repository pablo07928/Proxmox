#!/bin/bash
set -x
clear
# Constant Definitions
container_install_folder="/tmp/Cont_inst"
containers_before_install="$container_install_folder/prevms.txt"
containers_after_install="$container_install_folder/postvms.txt"
base_build_target="https://github.com/tteck/Proxmox/raw/main/ct/pihole.sh"
#base_build_target="https://raw.githubusercontent.com/pablo07928/Proxmox/main/scripts/Pihole1.sh"
#application_port="8080"
replication_account=holereplication



defaults_to_load() {
replication_account=holereplication
extra_admin_user=gonzapa1
extra_admin_pw=AnaCheP11
container_id=1500
container_ip=10.0.254.250
container_id2=1510
container_ip2=10.0.254.251
}


load_functions() {
    source <(curl -s https://raw.githubusercontent.com/pablo07928/Proxmox/main/functions/build.func)
    source <(curl -s https://raw.githubusercontent.com/pablo07928/Proxmox/main/functions/my.func.sh)
    variables
    color
}


base_build() {
    #msg_ok "saving containers before"
    pct list >$containers_before_install
    #msg_ok "starting pihole 1 install:      bash -c $(wget -qLO - $base_build_target)"
    bash -c "$(wget -qLO - $base_build_target)"
    #msg_ok "saving containers after"
    pct list >$containers_after_install
}


configure_application(){
    local container_id=$1
    local extra_admin_user=$2

pct exec $container_id -- bash -c "systemctl stop whisparr"
sleep 10
pct exec $container_id -- bash -c "mv /var/lib/whisparr/whisparr2.db /var/lib/whisparr/whisparr2.db.old"
pct exec $container_id -- bash -c "mv /var/lib/whisparr/config.xml /var/lib/whisparr/config.xml.old"
pct exec $container_id -- bash -c "unzip -o /media/scripts/whisparr/backups/whisparr_backup*.zip -d /var/lib/whisparr "
pct exec $container_id -- bash -c " chown $extra_admin_user:users /var/lib/whisparr/config.xml"
pct exec $container_id -- bash -c " chown $extra_admin_user:users /var/lib/whisparr/whisparr2.db"
pct exec $container_id -- bash -c "systemctl start whisparr"
}




#msg_ok "load functions"
load_functions
#msg_ok "prepare folder"
prepare_folder
extra_admin_user=$(extra_admin_account)
extra_admin_pw=$(extra_admin_password)




#msg_ok "installing PIhole 1"
base_build
container_id=$(find_container_id2)
container_ip=$(get_container_ip $container_id)
#msg_ok "Container ID = $container_id  Container IP = $container_ip"


#msg_ok "installing PIhole 2"
base_build
container_id2=$(find_container_id2)
container_ip2=$(get_container_ip $container_id)

#msg_ok "Container ID = $container_id  Container IP = $container_ip"
#msg_ok "Container ID = $container_id2  Container IP = $container_ip2"

#msg_ok " create_second_admin on container id:$container_id User Name: $extra_admin_user Password: $extra_admin_pw"

#msg_ok "Creating second admin on Pihole1"
create_second_admin $container_id $extra_admin_user $extra_admin_pw
#msg_ok "Creating replication account on Pihole1"
create_second_admin $container_id $replication_account $extra_admin_pw


#msg_ok "Creating second admin on Pihole2"
create_second_admin $container_id2 $extra_admin_user $extra_admin_pw
#msg_ok "Creating replication account on Pihole2"
create_second_admin $container_id2 $replication_account $extra_admin_pw


#msg_ok "Adding shares to Pihole1"
add_standard_shares2 $container_id
#msg_ok "Adding shares to Pihole1"
add_standard_shares2 $container_id2

#msg_info "restarting keepalive on both servers"
pct exec $container_id -- bash -c "apt install -y sshpass"
pct exec $container_id2 -- bash -c "apt install -y sshpass"
#msg_ok "Keepalive service restarted on both servers"

#pct exec $container_id -- bash -c "pihole -a -p $extra_admin_pw"
#pct exec $container_id2 -- bash -c "pihole -a -p $extra_admin_pw"

#msg_ok "Reboot Pihole1"
reboot_container2 $container_id $container_ip

#msg_ok "Reboot Pihole1"
reboot_container2 $container_id2 $container_ip2



#msg_info "generate ssh Key Pihole1 and copy to pihole2"
pct exec $container_id -- bash -c "ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -q -N ''"
pct exec $container_id -- bash -c "sshpass -p $extra_admin_pw ssh-copy-id -o StrictHostKeyChecking=no root@$container_ip2"
#msg_ok "generated ssh Key Pihole1 and copied  to Pihole2"

#msg_info "generate ssh Key or Pihole2 and copy to Pihole1"
pct exec $container_id2 -- bash -c "ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -q -N ''"
pct exec $container_id2 -- bash -c "ssh-copy-id -o StrictHostKeyChecking=no root@$container_ip"

#msg_ok "generated ssh Key for Pihole2 and copied  to Pihole1"


exit 0

#msg_info "Downloading mster script"
pct exec $container_id -- bash -c "wget -qLO - https://github.com/pablo07928/Proxmox/raw/main/scripts/pihole_ha/Master.sh > /etc/pihole/pihole-gemini.sh"
pct exec $container_id -- bash -c " chmod +x /etc/pihole/pihole-gemini.sh"
#msg_ok "Download succesfull"


#msg_info "Downloading slave script"
pct exec $container_id2 -- bash -c "wget -qLO - https://github.com/pablo07928/Proxmox/raw/main/scripts/pihole_ha/Slave.sh > /etc/pihole/pihole-gemini.sh"
pct exec $container_id2 -- bash -c " chmod +x /etc/pihole/pihole-gemini.sh"
#msg_ok "Download succesfull"


#msg_info "backing up original gravity script on both servers"
pct exec $container_id -- bash -c "cp /opt/pihole/gravity.sh /opt/pihole/gravity.sh.bak"
pct exec $container_id2 -- bash -c "cp /opt/pihole/gravity.sh /opt/pihole/gravity.sh.bak"
#msg_ok "backed up original gravity script on both servers"

#msg_info "modifying gravity script on both servers"
pct exec $container_id -- bash -c 'awk '\''/\"\$\{PIHOLE_COMMAND\}\" status/{print "su -c /usr/local/bin/pihole-gemini - pi"}1'\'' /opt/pihole/gravity.sh > temp && mv temp /opt/pihole/gravity.sh'
pct exec $container_id2 -- bash -c 'awk '\''/\"\$\{PIHOLE_COMMAND\}\" status/{print "su -c /usr/local/bin/pihole-gemini - pi"}1'\'' /opt/pihole/gravity.sh > temp && mv temp /opt/pihole/gravity.sh'
#msg_ok "modified gravity script on both servers"

#msg_info "installing keepalive service on pihole1"
pct exec $container_id -- bash -c "apt update && apt install keepalived libipset3 -y"
pct exec $container_id -- bash -c "systemctl enable keepalived.service"
#msg_ok "keepalive service installed on Pihole 1"

#msg_info "installing keepalive service on pihole2"
pct exec $container_id2 -- bash -c "apt update &&  apt install keepalived libipset3 -y"
pct exec $container_id2 -- bash -c "systemctl enable keepalived.service"
#msg_ok "keepalive service installed on Pihole 2"

#msg_info "creating /etc/scripts on  both servers"
pct exec $container_id1 -- bash -c "mkdir /etc/scripts"
pct exec $container_id2 -- bash -c "mkdir /etc/scripts"
#msg_ok "folders created"

#msg_info "downloading /etc/scripts/chk_ftl on  both servers"
pct exec $container_id -- bash -c "wget -qLO - https://github.com/pablo07928/Proxmox/raw/main/scripts/pihole_ha/chk_ftl> /etc/scripts/chk_ftl"
pct exec $container_id2 -- bash -c "wget -qLO - https://github.com/pablo07928/Proxmox/raw/main/scripts/pihole_ha/chk_ftl> /etc/scripts/chk_ftl"
#msg_ok "downloaded /etc/scripts/chk_ftl on both servers"

#msg_info "downloading /etc/keepalived/keepalived.conf on  both servers"
pct exec $container_id -- bash -c "wget -qLO - https://github.com/pablo07928/Proxmox/raw/main/scripts/pihole_ha/keepalivedM.conf> /etc/keepalived/keepalived.conf"
pct exec $container_id2 -- bash -c "wget -qLO - https://github.com/pablo07928/Proxmox/raw/main/scripts/pihole_ha/keepalivedS.conf> /etc/keepalived/keepalived.conf"
#msg_ok "downloaded /etc/keepalived/keepalived.conf on both servers"


#msg_info "restarting keepalive on both servers"
pct exec $container_id -- bash -c "systemctl restart keepalived.service"
pct exec $container_id2 -- bash -c "systemctl restart keepalived.service"
#msg_ok "Keepalive service restarted on both servers"